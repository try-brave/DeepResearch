# DeepResearch 一键启动脚本
# 用法: .\start.ps1

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=== DeepResearch 一键启动 ===" -ForegroundColor Cyan

# 1. 清理旧进程
Write-Host "[1/5] 清理旧 Python 进程..." -ForegroundColor Yellow
Get-Process python -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Write-Host "    进程清理完毕" -ForegroundColor Green

# 2. 启动依赖服务
Write-Host "[2/5] 启动 Docker 依赖 (PostgreSQL + Milvus)..." -ForegroundColor Yellow
docker compose up -d
Write-Host "    等待服务就绪..." -ForegroundColor Yellow
Start-Sleep -Seconds 5
Write-Host "    依赖服务已启动" -ForegroundColor Green

# 3. 启动后端
Write-Host "[3/5] 启动后端 FastAPI (port 8000)..." -ForegroundColor Yellow
$null = Start-Process -NoNewWindow -FilePath "$ProjectRoot\.venv\Scripts\python.exe" `
    -ArgumentList "$ProjectRoot\app\app_main.py" `
    -RedirectStandardOutput "$ProjectRoot\logs\backend.log" `
    -RedirectStandardError "$ProjectRoot\logs\backend_error.log"
Start-Sleep -Seconds 8

try {
    $health = Invoke-RestMethod -Uri "http://127.0.0.1:8000/health" -TimeoutSec 5
    Write-Host "    后端就绪: $($health.status)" -ForegroundColor Green
} catch {
    Write-Host "    后端启动异常，请检查 logs/backend.log" -ForegroundColor Red
    exit 1
}

# 4. 启动前端
Write-Host "[4/5] 启动前端 Vite (port 5173)..." -ForegroundColor Yellow
$NodeExe = "$env:USERPROFILE\.workbuddy\binaries\node\versions\22.22.2\node.exe"
if (-not (Test-Path $NodeExe)) {
    $NodeExe = "node"
}
$null = Start-Process -NoNewWindow -FilePath $NodeExe `
    -ArgumentList "$ProjectRoot\front\agent_front\node_modules\vite\bin\vite.js", "--host", "0.0.0.0" `
    -WorkingDirectory "$ProjectRoot\front\agent_front" `
    -RedirectStandardOutput "$ProjectRoot\logs\frontend.log" `
    -RedirectStandardError "$ProjectRoot\logs\frontend_error.log"
Start-Sleep -Seconds 6

try {
    $null = Invoke-WebRequest -Uri "http://127.0.0.1:5173" -TimeoutSec 5
    Write-Host "    前端就绪" -ForegroundColor Green
} catch {
    Write-Host "    前端启动异常，请检查 logs/frontend.log" -ForegroundColor Red
    exit 1
}

# 5. 打开浏览器
Write-Host "[5/5] 打开浏览器..." -ForegroundColor Yellow
Start-Process "http://127.0.0.1:5173"

Write-Host ""
Write-Host "=== DeepResearch 启动完毕 ===" -ForegroundColor Cyan
Write-Host "  前端: http://127.0.0.1:5173" -ForegroundColor White
Write-Host "  后端: http://127.0.0.1:8000" -ForegroundColor White
Write-Host "  API文档: http://127.0.0.1:8000/docs" -ForegroundColor White
Write-Host "  日志: $ProjectRoot\logs\" -ForegroundColor Gray
