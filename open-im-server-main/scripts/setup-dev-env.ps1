<#
  OpenIM Server 开发环境搭建脚本 (Windows)
  运行方式: 以管理员身份打开 PowerShell, 执行 .\scripts\setup-dev-env.ps1
#>

param(
    [switch]$SkipGo,
    [switch]$SkipDocker,
    [switch]$SkipTools
)

$ErrorActionPreference = "Stop"
$GoVersion = "1.22.7"

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }

# ---- 1. 安装 Go ----
if (-not $SkipGo) {
    Write-Step "检查 Go 安装..."
    $goCmd = Get-Command go -ErrorAction SilentlyContinue
    if ($goCmd) {
        $currentVer = (go version) -replace "go version go(\S+).*", '$1'
        Write-Host "Go 已安装: $currentVer"
    } else {
        Write-Step "下载并安装 Go $GoVersion ..."
        $installer = "$env:TEMP\go${GoVersion}.windows-amd64.msi"
        $url = "https://go.dev/dl/go${GoVersion}.windows-amd64.msi"

        Write-Host "下载地址: $url"
        Invoke-WebRequest -Uri $url -OutFile $installer -UseBasicParsing

        Write-Host "安装中... (需要管理员权限)"
        Start-Process msiexec.exe -ArgumentList "/i `"$installer`" /quiet /norestart" -Wait -Verb RunAs

        # 刷新 PATH
        $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
        $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
        $env:Path = "$machinePath;$userPath"

        if (Get-Command go -ErrorAction SilentlyContinue) {
            Write-Host "Go $GoVersion 安装成功!" -ForegroundColor Green
        } else {
            Write-Host "Go 安装完成，请重启终端后生效" -ForegroundColor Yellow
        }

        Remove-Item $installer -ErrorAction SilentlyContinue
    }
}

# ---- 2. 安装 Go 开发工具 ----
if (-not $SkipTools) {
    Write-Step "安装 Go 开发工具..."

    $tools = @(
        "golang.org/x/tools/gopls@latest",
        "github.com/go-delve/delve/cmd/dlv@latest",
        "github.com/golangci/golangci-lint/cmd/golangci-lint@latest",
        "golang.org/x/tools/cmd/goimports@latest",
        "mvdan.cc/gofumpt@latest",
        "github.com/fatih/gomodifytags@latest",
        "github.com/josharian/impl@latest",
        "github.com/cweill/gotests/gotests@latest"
    )

    foreach ($tool in $tools) {
        $name = ($tool -split "/")[-1] -replace "@.*", ""
        Write-Host "  安装 $name ..."
        go install $tool 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    OK" -ForegroundColor Green
        } else {
            Write-Host "    FAILED (可稍后手动安装)" -ForegroundColor Yellow
        }
    }
}

# ---- 3. 检查 Docker ----
if (-not $SkipDocker) {
    Write-Step "检查 Docker..."
    $dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
    if ($dockerCmd) {
        docker --version
        docker compose version 2>$null
        Write-Host "Docker 已就绪" -ForegroundColor Green
    } else {
        Write-Host "Docker 未安装。请手动安装 Docker Desktop:" -ForegroundColor Yellow
        Write-Host "  https://www.docker.com/products/docker-desktop/" -ForegroundColor Yellow
    }
}

# ---- 4. 检查项目依赖 ----
Write-Step "检查项目 Go 模块..."
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Push-Location $projectRoot

if (Get-Command go -ErrorAction SilentlyContinue) {
    if (Test-Path "go.mod") {
        Write-Host "运行 go mod tidy..."
        go mod tidy
        Write-Host "Go 模块依赖检查完成" -ForegroundColor Green
    }
}
Pop-Location

Write-Step "环境搭建完成!"
Write-Host @"

开发环境清单:
  [Go]      go version  => 检查 Go 编译器
  [Docker]  docker compose up -d mongodb redis etcd kafka minio  => 启动依赖服务
  [Build]   go build ./...  => 编译项目
  [Test]    go test ./...   => 运行测试
  [Lint]    golangci-lint run ./...  => 代码检查
  [Run]     go run cmd/main.go -c config/  => 启动服务(standalone模式)

VS Code 推荐操作:
  1. 重新打开工作区: d:\procket\IMCHAT\open-im-server-main
  2. 安装推荐插件: Ctrl+Shift+P => "Extensions: Show Recommended Extensions"
  3. F5 启动调试
"@
