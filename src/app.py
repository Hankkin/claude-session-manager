import rumps
import subprocess
import tempfile
from pathlib import Path
import sys

from models import load_history, group_sessions, load_session_content, delete_session_from_history, SessionSummary


class SessionManagerApp:
    """Claude 会话管理菜单栏应用"""

    DEFAULT_LIMIT = 20
    SHOW_ALL = 0

    def __init__(self):
        # 获取图标路径
        if hasattr(sys, 'frozen'):
            # Bundled app (py2app)
            app_dir = Path(sys.executable).parent.parent
            icon_path = app_dir / "Resources" / "app.icns"
        else:
            # Script mode (development)
            app_dir = Path(__file__).parent
            icon_path = app_dir.parent / "app.icns"

        self.app = rumps.App("Claude", icon=str(icon_path) if icon_path.exists() else None)

        # 隐藏 Dock 图标
        try:
            from AppKit import NSApp
            NSApp.setActivationPolicy_(0)
        except:
            pass

        self.app.menu = []
        self.sessions: list[SessionSummary] = []
        self.session_map = {}
        self.session_limit = self.DEFAULT_LIMIT
        self.history_path = Path.home() / ".claude" / "history.jsonl"

        self.refresh_sessions()
        self.build_menu()

        self._timer = rumps.Timer(self.on_timer, 60)
        self._timer.start()

    def refresh_sessions(self):
        """刷新会话列表"""
        history = load_history(str(self.history_path))
        if self.session_limit == self.SHOW_ALL:
            self.sessions = group_sessions(history, limit=None)
        else:
            self.sessions = group_sessions(history, limit=self.session_limit)

    def build_menu(self):
        """构建菜单"""
        self.app.menu.clear()
        self.session_map.clear()

        if self.session_limit == self.SHOW_ALL:
            title = f"📋 全部会话 ({len(self.sessions)} 条)"
        else:
            title = f"📋 最近 {self.session_limit} 条会话"

        self.app.menu.add(rumps.MenuItem(title))
        self.app.menu.add(rumps.separator)

        mode_menu = rumps.MenuItem("🔀 加载模式")
        mode_menu.add(rumps.MenuItem("最近 20 条", callback=lambda s: self._set_limit(20)))
        mode_menu.add(rumps.MenuItem("最近 50 条", callback=lambda s: self._set_limit(50)))
        mode_menu.add(rumps.MenuItem("最近 100 条", callback=lambda s: self._set_limit(100)))
        mode_menu.add(rumps.MenuItem("全部会话", callback=lambda s: self._set_limit(0)))
        self.app.menu.add(mode_menu)
        self.app.menu.add(rumps.separator)

        if not self.sessions:
            self.app.menu.add(rumps.MenuItem("(无可用会话)"))
            self._add_bottom_buttons()
            return

        for session in self.sessions:
            short_id = session.session_id.split("-")[-1][:8]
            title = f"{session.formatted_time} | {session.short_project}"

            self.session_map[short_id] = session
            session_item = rumps.MenuItem(title)

            preview_item = rumps.MenuItem(f"📝 {session.truncated_message_long}")
            preview_item.set_callback(lambda s: None)

            copy_item = rumps.MenuItem("复制 Session ID",
                                       callback=lambda s, sid=session.session_id: self._copy_session_id(sid))
            preview_content_item = rumps.MenuItem("预览会话内容",
                                                  callback=lambda s, sid=session.session_id: self._preview_session(sid))
            resume_item = rumps.MenuItem("🚀 恢复此会话",
                                        callback=lambda s, sid=session.session_id: self._resume_session(sid))
            delete_item = rumps.MenuItem("🗑️ 删除此会话",
                                        callback=lambda s, sid=session.session_id: self._delete_session(sid))

            session_item.add(preview_item)
            session_item.add(copy_item)
            session_item.add(preview_content_item)
            session_item.add(resume_item)
            session_item.add(delete_item)

            self.app.menu.add(session_item)

        self._add_bottom_buttons()

    def _add_bottom_buttons(self):
        """添加底部按钮"""
        self.app.menu.add(rumps.separator)
        self.app.menu.add(rumps.MenuItem("🔄 刷新会话", callback=lambda s: self._do_refresh()))
        self.app.menu.add(rumps.MenuItem("❌ 退出", callback=lambda s: self._do_quit()))

    def _copy_session_id(self, session_id):
        """复制 session ID"""
        subprocess.run(["pbcopy"], input=session_id.encode(), check=True)
        self.show_notification("已复制 Session ID", session_id)

    def _preview_session(self, session_id):
        """预览会话内容"""
        session = None
        for s in self.sessions:
            if s.session_id == session_id:
                session = s
                break

        if not session:
            self.show_notification("错误", "未找到会话")
            return

        content = load_session_content(session_id, session.project, max_lines=15)

        temp_file = tempfile.NamedTemporaryFile(
            mode='w',
            suffix='.txt',
            delete=False,
            encoding='utf-8'
        )
        temp_file.write(f"会话 ID: {session_id}\n")
        temp_file.write(f"项目: {session.project}\n")
        temp_file.write(f"消息数: {session.message_count}\n")
        temp_file.write("=" * 50 + "\n\n")
        temp_file.write(content)
        temp_file.close()

        subprocess.run(["open", "-t", temp_file.name])

    def _resume_session(self, session_id):
        """恢复 Claude Code 会话"""
        session = None
        for s in self.sessions:
            if s.session_id == session_id:
                session = s
                break

        cmd = f'/bin/bash -l -c "claude --resume {session_id}"'

        if session and session.project:
            subprocess.Popen(
                cmd,
                shell=True,
                cwd=session.project,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
        else:
            subprocess.Popen(
                cmd,
                shell=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
        self.show_notification("正在启动 Claude Code", f"恢复会话 {session_id[:8]}...")

    def _set_limit(self, limit: int):
        """设置显示数量限制"""
        self.session_limit = limit if limit > 0 else self.SHOW_ALL
        self.refresh_sessions()
        self.build_menu()
        if self.session_limit == self.SHOW_ALL:
            self.show_notification("已切换", f"显示全部 {len(self.sessions)} 条会话")
        else:
            self.show_notification("已切换", f"显示最近 {self.session_limit} 条会话")

    def _delete_session(self, session_id: str):
        """删除指定会话"""
        try:
            result = subprocess.run([
                "osascript", "-e",
                f'display dialog "确定要删除此会话吗？\\n\\nSession ID: {session_id[:8]}..." '
                f'with title "确认删除" buttons {{"取消", "删除"}} default button 1 cancel button 1'
            ], capture_output=True, text=True)
            if result.returncode != 0:
                return
        except subprocess.CalledProcessError:
            return

        if delete_session_from_history(str(self.history_path), session_id):
            self.show_notification("已删除", f"会话 {session_id[:8]}... 已从历史记录中移除")
            self.refresh_sessions()
            self.build_menu()
        else:
            self.show_notification("删除失败", "无法删除会话")

    def _do_refresh(self):
        """刷新会话列表"""
        self.refresh_sessions()
        self.build_menu()
        self.show_notification("会话已刷新", f"加载了 {len(self.sessions)} 条会话")

    def _do_quit(self):
        """退出应用"""
        rumps.quit_application()

    def on_timer(self, sender):
        """定时刷新"""
        self.refresh_sessions()
        self.build_menu()

    @staticmethod
    def show_notification(title: str, message: str):
        """显示通知"""
        try:
            subprocess.run([
                "osascript", "-e",
                f'display notification "{message}" with title "{title}"'
            ], check=True, capture_output=True)
        except subprocess.CalledProcessError:
            pass

    def run(self):
        """运行应用"""
        self.app.run()
