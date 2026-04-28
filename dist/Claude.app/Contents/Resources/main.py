#!/usr/bin/env python3
"""Claude Session Manager - macOS menu bar app"""

import rumps
import subprocess
import tempfile
import json
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Optional
import sys


@dataclass
class SessionSummary:
    session_id: str
    project: str
    first_message: str
    timestamp: int
    message_count: int = 0

    @property
    def formatted_time(self) -> str:
        dt = datetime.fromtimestamp(self.timestamp / 1000)
        now = datetime.now()
        today_start = datetime(now.year, now.month, now.day)
        if dt >= today_start:
            return dt.strftime("今天 %H:%M")
        elif dt >= today_start.replace(day=now.day - 1):
            return dt.strftime("昨天 %H:%M")
        else:
            return dt.strftime("%m-%d %H:%M")

    @property
    def short_project(self) -> str:
        if self.project == "/Users/hankkin":
            return "~"
        return self.project.replace("/Users/hankkin/", "~/").replace("-Users-hankkin", "~")

    @property
    def truncated_message_long(self) -> str:
        msg = self.first_message.replace("\n", " ").strip()
        if len(msg) > 150:
            return msg[:150] + "..."
        return msg


def load_history(file_path: str) -> list[dict]:
    history_path = Path(file_path)
    if not history_path.exists():
        return []
    sessions = []
    with open(history_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                try:
                    sessions.append(json.loads(line))
                except json.JSONDecodeError:
                    continue
    return sessions


def group_sessions(history: list[dict], limit: int = 20) -> list[SessionSummary]:
    from collections import defaultdict
    grouped = defaultdict(list)
    for entry in history:
        session_id = entry.get("sessionId")
        if session_id:
            grouped[session_id].append(entry)
    summaries = []
    for session_id, entries in grouped.items():
        entries.sort(key=lambda x: x.get("timestamp", 0))
        first_msg = ""
        project = ""
        timestamp = 0
        for entry in entries:
            display = entry.get("display", "")
            if display and not first_msg:
                first_msg = display[:100] if len(display) > 100 else display
            if entry.get("project") and not project:
                project = entry.get("project")
            timestamp = max(timestamp, entry.get("timestamp", 0))
        if first_msg:
            summaries.append(SessionSummary(
                session_id=session_id,
                project=project or "~",
                first_message=first_msg,
                timestamp=timestamp,
                message_count=len(entries)
            ))
    summaries.sort(key=lambda x: x.timestamp, reverse=True)
    return summaries[:limit]


def find_session_file(session_id: str, project: str) -> Optional[Path]:
    project_hash = project.replace("/", "-").replace("~", "-Users-hankkin")
    session_file = Path.home() / ".claude" / "projects" / project_hash / f"{session_id}.jsonl"
    if session_file.exists():
        return session_file
    projects_dir = Path.home() / ".claude" / "projects"
    for proj_dir in projects_dir.iterdir():
        if proj_dir.is_dir():
            candidate = proj_dir / f"{session_id}.jsonl"
            if candidate.exists():
                return candidate
    return None


def load_session_content(session_id: str, project: str, max_lines: int = 20) -> str:
    session_file = find_session_file(session_id, project)
    if not session_file:
        return "会话文件未找到"
    lines = []
    user_count = 0
    try:
        with open(session_file, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    entry = json.loads(line)
                except json.JSONDecodeError:
                    continue
                msg_type = entry.get("type")
                if msg_type == "user":
                    content = entry.get("display", "")
                    if not content and isinstance(entry.get("message"), dict):
                        content_list = entry.get("message", {}).get("content", [])
                        if isinstance(content_list, list):
                            for c in content_list:
                                if isinstance(c, dict) and c.get("type") == "text":
                                    content = c.get("text", "")
                                    break
                        elif isinstance(content_list, str):
                            content = content_list
                    if content:
                        user_count += 1
                        if user_count > max_lines // 2:
                            lines.append(f"...\n(还有更多消息)")
                            break
                        lines.append(f"[用户 {user_count}]\n{content[:200]}")
                elif msg_type == "assistant" and user_count > 0:
                    msg_content = entry.get("message", {}).get("content", [])
                    if isinstance(msg_content, list):
                        for c in msg_content:
                            if isinstance(c, dict) and c.get("type") == "text":
                                content = c.get("text", "")[:300]
                                if content:
                                    lines.append(f"[助手]\n{content}")
                                    break
                    if len(lines) >= max_lines:
                        break
    except Exception as e:
        return f"读取错误: {str(e)}"
    if not lines:
        return "会话内容为空"
    return "\n\n".join(lines)


def delete_session_from_history(history_path: str, session_id: str) -> bool:
    history_file = Path(history_path)
    if not history_file.exists():
        return False
    try:
        with open(history_file, "r", encoding="utf-8") as f:
            lines = f.readlines()
        remaining_lines = []
        deleted_count = 0
        for line in lines:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
                if entry.get("sessionId") == session_id:
                    deleted_count += 1
                    continue
                remaining_lines.append(line)
            except json.JSONDecodeError:
                continue
        with open(history_file, "w", encoding="utf-8") as f:
            for line in remaining_lines:
                f.write(line + "\n")
        return deleted_count > 0
    except Exception:
        return False


class SessionManagerApp:
    DEFAULT_LIMIT = 20
    SHOW_ALL = 0

    def __init__(self):
        if hasattr(sys, 'frozen'):
            app_dir = Path(sys.executable).parent.parent
            # Try PNG first for status bar, fallback to icns
            icon_path = app_dir / "Resources" / "app.png"
            if not icon_path.exists():
                icon_path = app_dir / "Resources" / "app.icns"
        else:
            app_dir = Path(__file__).parent
            icon_path = app_dir / "app.png"
            if not icon_path.exists():
                icon_path = app_dir / "app.icns"

        self.app = rumps.App("Claude", icon=str(icon_path) if icon_path.exists() else None)
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
        self.select_mode = False  # 选择模式
        self.selected_sessions = set()  # 已选择的会话
        self.refresh_sessions()
        self.build_menu()
        self._timer = rumps.Timer(self.on_timer, 60)
        self._timer.start()

    def refresh_sessions(self):
        history = load_history(str(self.history_path))
        if self.session_limit == self.SHOW_ALL:
            self.sessions = group_sessions(history, limit=None)
        else:
            self.sessions = group_sessions(history, limit=self.session_limit)

    def build_menu(self):
        self.app.menu.clear()
        self.session_map.clear()

        # 标题
        if self.session_limit == self.SHOW_ALL:
            title = f"📋 全部会话 ({len(self.sessions)} 条)"
        else:
            title = f"📋 最近 {self.session_limit} 条会话"
        self.app.menu.add(rumps.MenuItem(title))
        self.app.menu.add(rumps.separator)

        # 选择模式开关
        select_mode_title = "☑️ 选择模式" if self.select_mode else "☐ 选择模式"
        self.app.menu.add(rumps.MenuItem(select_mode_title, callback=lambda s: self._toggle_select_mode()))

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
            session_item = rumps.MenuItem(title)

            if self.select_mode:
                # 选择模式：显示选择/取消选择子菜单
                check_status = "☑️ 已选择" if session.session_id in self.selected_sessions else "☐ 未选择"
                select_item = rumps.MenuItem(check_status,
                    callback=lambda s, sid=session.session_id: self._toggle_session_selection(sid))
                session_item.add(select_item)
            else:
                # 普通模式：显示完整子菜单
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

            self.session_map[short_id] = session
            self.app.menu.add(session_item)

        self._add_bottom_buttons()

    def _add_bottom_buttons(self):
        self.app.menu.add(rumps.separator)
        if self.select_mode and self.selected_sessions:
            self.app.menu.add(rumps.MenuItem(f"🗑️ 删除所选 ({len(self.selected_sessions)} 项)",
                                            callback=lambda s: self._delete_selected_sessions()))
        self.app.menu.add(rumps.MenuItem("🔄 刷新会话", callback=lambda s: self._do_refresh()))
        self.app.menu.add(rumps.MenuItem("❌ 退出", callback=lambda s: self._do_quit()))

    def _toggle_select_mode(self):
        """切换选择模式"""
        self.select_mode = not self.select_mode
        if not self.select_mode:
            self.selected_sessions.clear()
        self.build_menu()

    def _toggle_session_selection(self, session_id: str):
        """切换会话选择状态"""
        if session_id in self.selected_sessions:
            self.selected_sessions.remove(session_id)
        else:
            self.selected_sessions.add(session_id)
        self.build_menu()

    def _delete_selected_sessions(self):
        """删除所有选中的会话"""
        import threading

        def confirm_delete():
            count = len(self.selected_sessions)
            result = subprocess.run([
                "osascript", "-e",
                f'display dialog "确定要删除所选的 {count} 个会话吗？此操作不可撤销。" '
                f'with title "确认删除" buttons {{"取消", "删除"}} default button 1 cancel button 1'
            ], capture_output=True, text=True)
            if result.returncode == 0:
                deleted = 0
                for sid in list(self.selected_sessions):
                    if delete_session_from_history(str(self.history_path), sid):
                        deleted += 1
                self.selected_sessions.clear()
                self.select_mode = False
                self.show_notification("已删除", f"删除了 {deleted} 个会话")
                self.refresh_sessions()
                self.build_menu()

        thread = threading.Thread(target=confirm_delete)
        thread.start()

    def _copy_session_id(self, session_id):
        subprocess.run(["pbcopy"], input=session_id.encode(), check=True)
        self.show_notification("已复制 Session ID", session_id)

    def _preview_session(self, session_id):
        session = None
        for s in self.sessions:
            if s.session_id == session_id:
                session = s
                break
        if not session:
            self.show_notification("错误", "未找到会话")
            return
        content = load_session_content(session_id, session.project, max_lines=15)
        temp_file = tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False, encoding='utf-8')
        temp_file.write(f"会话 ID: {session_id}\n")
        temp_file.write(f"项目: {session.project}\n")
        temp_file.write(f"消息数: {session.message_count}\n")
        temp_file.write("=" * 50 + "\n\n")
        temp_file.write(content)
        temp_file.close()
        subprocess.run(["open", "-t", temp_file.name])

    def _resume_session(self, session_id):
        session = None
        for s in self.sessions:
            if s.session_id == session_id:
                session = s
                break
        cmd = f'/bin/bash -l -c "claude --resume {session_id}"'
        if session and session.project:
            subprocess.Popen(cmd, shell=True, cwd=session.project, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        else:
            subprocess.Popen(cmd, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        self.show_notification("正在启动 Claude Code", f"恢复会话 {session_id[:8]}...")

    def _set_limit(self, limit: int):
        self.session_limit = limit if limit > 0 else self.SHOW_ALL
        self.refresh_sessions()
        self.build_menu()
        if self.session_limit == self.SHOW_ALL:
            self.show_notification("已切换", f"显示全部 {len(self.sessions)} 条会话")
        else:
            self.show_notification("已切换", f"显示最近 {self.session_limit} 条会话")

    def _delete_session(self, session_id: str):
        # 使用后台进程显示确认对话框，避免阻塞
        import threading

        def confirm_delete():
            result = subprocess.run([
                "osascript", "-e",
                f'display dialog "确定要删除此会话吗？\\n\\nSession ID: {session_id[:8]}..." '
                f'with title "确认删除" buttons {{"取消", "删除"}} default button 1 cancel button 1'
            ], capture_output=True, text=True)
            if result.returncode == 0:
                # 用户点击了"删除"
                if delete_session_from_history(str(self.history_path), session_id):
                    self.show_notification("已删除", f"会话 {session_id[:8]}... 已从历史记录中移除")
                    self.refresh_sessions()
                    self.build_menu()
                else:
                    self.show_notification("删除失败", "无法删除会话")

        thread = threading.Thread(target=confirm_delete)
        thread.start()

    def _do_refresh(self):
        self.refresh_sessions()
        self.build_menu()
        self.show_notification("会话已刷新", f"加载了 {len(self.sessions)} 条会话")

    def _do_quit(self):
        rumps.quit_application()

    def on_timer(self, sender):
        self.refresh_sessions()
        self.build_menu()

    @staticmethod
    def show_notification(title: str, message: str):
        try:
            subprocess.run([
                "osascript", "-e",
                f'display notification "{message}" with title "{title}"'
            ], check=True, capture_output=True)
        except subprocess.CalledProcessError:
            pass

    def run(self):
        self.app.run()


if __name__ == "__main__":
    app = SessionManagerApp()
    app.run()
