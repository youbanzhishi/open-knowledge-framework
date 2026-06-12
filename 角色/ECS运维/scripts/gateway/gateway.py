#!/usr/bin/env python3
"""Remote Gateway - 轻量HTTP命令网关，支持Token认证+IP白名单+操作日志"""

import yaml
import subprocess
import urllib.parse
import ipaddress
import time
import os
import logging
from logging.handlers import RotatingFileHandler
from http.server import HTTPServer, BaseHTTPRequestHandler

# 加载配置
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_PATH = os.environ.get("GATEWAY_CONFIG", os.path.join(SCRIPT_DIR, "config.yaml"))

with open(CONFIG_PATH, "r") as f:
    CFG = yaml.safe_load(f)

# 日志
log_cfg = CFG.get("logging", {})
log_file = log_cfg.get("file", "/var/log/remote-gateway.log")
log_max = log_cfg.get("max_size_mb", 10) * 1024 * 1024
log_backup = log_cfg.get("backup_count", 3)

os.makedirs(os.path.dirname(log_file), exist_ok=True)
logger = logging.getLogger("gateway")
logger.setLevel(logging.INFO)
handler = RotatingFileHandler(log_file, maxBytes=log_max, backupCount=log_backup)
handler.setFormatter(logging.Formatter("[%(asctime)s] %(message)s"))
logger.addHandler(handler)
# 同时输出到控制台
console = logging.StreamHandler()
console.setFormatter(logging.Formatter("[%(asctime)s] %(message)s"))
logger.addHandler(console)

# 预编译IP白名单
ALLOWED_NETWORKS = [ipaddress.ip_network(cidr) for cidr in CFG.get("auth", {}).get("allowed_cidrs", [])]
TOKEN = CFG.get("auth", {}).get("token", "")
EXEC_TIMEOUT = CFG.get("exec", {}).get("timeout", 30)


def ip_allowed(client_ip):
    try:
        addr = ipaddress.ip_address(client_ip)
        return any(addr in net for net in ALLOWED_NETWORKS)
    except ValueError:
        return False


class GatewayHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        client = self.client_address[0]
        params = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)

        # IP白名单
        if not ip_allowed(client):
            logger.warning(f"DENY(ip) {client}")
            self.send_response(403)
            self.end_headers()
            self.wfile.write(b"forbidden")
            return

        # Token认证
        if params.get("token", [""])[0] != TOKEN:
            logger.warning(f"DENY(token) {client}")
            self.send_response(401)
            self.end_headers()
            self.wfile.write(b"unauthorized")
            return

        cmd = params.get("cmd", ["echo ok"])[0]
        logger.info(f"EXEC {client} | {cmd}")

        try:
            out = subprocess.check_output(
                cmd, shell=True, stderr=subprocess.STDOUT, timeout=EXEC_TIMEOUT
            ).decode(errors="replace")
        except subprocess.TimeoutExpired:
            out = f"ERROR: command timed out ({EXEC_TIMEOUT}s)"
            logger.error(f"TIMEOUT {client} | {cmd}")
        except subprocess.CalledProcessError as e:
            out = e.output.decode(errors="replace") if e.output else f"ERROR: exit code {e.returncode}"
            logger.error(f"FAIL({e.returncode}) {client} | {cmd}")
        except Exception as e:
            out = f"ERROR: {e}"
            logger.error(f"ERROR {client} | {cmd} | {e}")

        logger.info(f"RESULT {client} | {out[:200]}")
        self.send_response(200)
        self.end_headers()
        self.wfile.write(out.encode())

    def log_message(self, format, *args):
        # 禁用默认的HTTP日志，用我们自己的
        pass


def main():
    srv_cfg = CFG.get("server", {})
    host = srv_cfg.get("host", "0.0.0.0")
    port = srv_cfg.get("port", 7772)
    logger.info(f"Gateway starting on {host}:{port}")
    server = HTTPServer((host, port), GatewayHandler)
    server.serve_forever()


if __name__ == "__main__":
    main()
