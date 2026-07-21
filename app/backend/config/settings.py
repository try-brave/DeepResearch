"""服务层配置：仅在 app_main.py 中 load_dotenv 之后使用，不重复加载 .env。"""

import os
from pathlib import Path


class AppSettings:
    """FastAPI 服务运行时配置，从已加载的环境变量读取。"""

    app_name: str
    app_env: str
    host: str
    port: int
    cors_allow_origins: str
    config_path: str

    def __init__(self) -> None:
        self.app_name = os.getenv("APP_NAME", "DeepResearch Multi-Agent Assistant")
        self.app_env = os.getenv("APP_ENV", "development")
        self.host = os.getenv("HOST", "0.0.0.0")
        self.port = int(os.getenv("PORT", "8000"))
        self.cors_allow_origins = os.getenv(
            "CORS_ALLOW_ORIGINS", "http://localhost:5173,http://127.0.0.1:5173"
        )
        self.config_path = os.getenv(
            "CONFIG_PATH",
            str(Path(__file__).resolve().parents[3] / "config.json"),
        )

    def cors_origins(self) -> list[str]:
        values = [item.strip() for item in self.cors_allow_origins.split(",")]
        return [item for item in values if item]
