import json
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Optional


@dataclass
class SessionSummary:
    """会话摘要信息"""
    session_id: str
    project: str
    first_message: str
    timestamp: int
    message_count: int = 0

    @property
    def formatted_time(self) -> str:
        """格式化时间显示"""
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
        """简化项目路径显示"""
        if self.project == "/Users/hankkin":
            return "~"
        home = str(Path.home()).replace("/", "")
        return self.project.replace(f"/Users/hankkin/", "~/").replace("-Users-hankkin", "~")

    @property
    def truncated_message(self) -> str:
        """截断消息文本"""
        msg = self.first_message.replace("\n", " ").strip()
        if len(msg) > 80:
            return msg[:80] + "..."
        return msg

    @property
    def truncated_message_long(self) -> str:
        """更长的消息预览"""
        msg = self.first_message.replace("\n", " ").strip()
        if len(msg) > 150:
            return msg[:150] + "..."
        return msg


def load_history(file_path: str) -> list[dict]:
    """加载历史记录文件"""
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
    """将会话按 sessionId 分组并返回摘要"""
    from collections import defaultdict

    # 按 sessionId 分组
    grouped = defaultdict(list)
    for entry in history:
        session_id = entry.get("sessionId")
        if session_id:
            grouped[session_id].append(entry)

    # 构建会话摘要
    summaries = []
    for session_id, entries in grouped.items():
        # 按时间排序
        entries.sort(key=lambda x: x.get("timestamp", 0))

        # 获取第一条消息作为摘要
        first_msg = ""
        project = ""
        timestamp = 0

        for entry in entries:
            # history.jsonl 格式: display 字段就是用户输入
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

    # 按时间倒序排序
    summaries.sort(key=lambda x: x.timestamp, reverse=True)

    return summaries[:limit]


def find_session_file(session_id: str, project: str) -> Optional[Path]:
    """查找会话文件路径"""
    # 尝试直接路径
    project_hash = project.replace("/", "-").replace("~", "-Users-hankkin")
    session_file = Path.home() / ".claude" / "projects" / project_hash / f"{session_id}.jsonl"

    if session_file.exists():
        return session_file

    # 在整个 projects 目录搜索
    projects_dir = Path.home() / ".claude" / "projects"
    for proj_dir in projects_dir.iterdir():
        if proj_dir.is_dir():
            candidate = proj_dir / f"{session_id}.jsonl"
            if candidate.exists():
                return candidate

    return None


def load_session_content(session_id: str, project: str, max_lines: int = 20) -> str:
    """加载会话内容，返回格式化的文本"""
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
                    # 用户消息
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
                    # 助手回复（只显示第一条）
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
    """从 history.jsonl 中删除指定 session 的所有记录"""
    history_file = Path(history_path)
    if not history_file.exists():
        return False

    try:
        # 读取所有行
        with open(history_file, "r", encoding="utf-8") as f:
            lines = f.readlines()

        # 过滤掉指定 session_id 的行
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

        # 写回文件
        with open(history_file, "w", encoding="utf-8") as f:
            for line in remaining_lines:
                f.write(line + "\n")

        return deleted_count > 0

    except Exception:
        return False
