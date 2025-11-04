#!/usr/bin/env python3
"""
Dummy WebSocket server for Tauri iOS builds.
Handles WebSocket handshake and JSON-RPC requests to satisfy Tauri CLI requirements.
"""
import socket
import sys
import hashlib
import base64
import json

def handle_websocket_handshake(conn):
    """Handle WebSocket HTTP upgrade request and keep connection alive"""
    try:
        request = conn.recv(4096).decode('utf-8')
        if not request:
            return
        lines = request.split('\r\n')
        key = None
        for line in lines:
            if line.startswith('Sec-WebSocket-Key:'):
                key = line.split(':', 1)[1].strip()
                break
        if key:
            magic_string = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'
            accept_key = base64.b64encode(
                hashlib.sha1((key + magic_string).encode()).digest()
            ).decode()
            accept_header = 'Sec-WebSocket-Accept: ' + accept_key + '\r\n'
            response = (
                'HTTP/1.1 101 Switching Protocols\r\n'
                'Upgrade: websocket\r\n'
                'Connection: Upgrade\r\n'
                + accept_header +
                '\r\n'
            )
            conn.send(response.encode('utf-8'))
            
            # Keep connection open and handle WebSocket frames with JSON-RPC responses
            conn.settimeout(30.0)
            try:
                while True:
                    data = conn.recv(4096)
                    if not data:
                        break
                    
                    # Parse WebSocket frame (simplified - assumes masked client frames)
                    if len(data) < 6:
                        break
                    
                    # Check for close frame
                    if (data[0] & 0x0F) == 0x8:
                        close_frame = bytearray([0x88, 0x00])
                        conn.send(close_frame)
                        break
                    
                    # For text frames, decode and respond with JSON-RPC response
                    if (data[0] & 0x0F) == 0x1:  # Text frame
                        # Extract payload (skip frame header and mask)
                        mask_start = 2
                        if data[1] & 0x7F == 126:
                            mask_start = 4
                        elif data[1] & 0x7F == 127:
                            mask_start = 10
                        mask = data[mask_start:mask_start+4]
                        payload_start = mask_start + 4
                        payload_len = data[1] & 0x7F
                        if payload_len == 126:
                            payload_len = (data[2] << 8) | data[3]
                            payload_start = 8
                        elif payload_len == 127:
                            payload_start = 14
                        
                        payload = bytearray()
                        for i in range(payload_len):
                            payload.append(data[payload_start + i] ^ mask[i % 4])
                        
                        # Try to parse as JSON-RPC and send appropriate response
                        try:
                            req = json.loads(payload.decode('utf-8'))
                            # Build complete CLI options response that Tauri expects
                            result = {
                                "dev": False,
                                "args": [],
                                "noise_level": "Polite",
                                "target": None,
                                "features": [],
                                "release": False,
                                "debug": False,
                                "verbose": False,
                                "vars": {},
                                "config": []
                            }
                            
                            # Send JSON-RPC response
                            response_obj = {
                                "jsonrpc": "2.0",
                                "id": req.get("id"),
                                "result": result
                            }
                            response_json = json.dumps(response_obj)
                            # Send as WebSocket text frame
                            response_frame = bytearray([0x81])  # FIN + text frame
                            response_len = len(response_json)
                            if response_len < 126:
                                response_frame.append(response_len)
                            elif response_len < 65536:
                                response_frame.append(126)
                                response_frame.append((response_len >> 8) & 0xFF)
                                response_frame.append(response_len & 0xFF)
                            response_frame.extend(response_json.encode('utf-8'))
                            conn.send(response_frame)
                        except:
                            # If JSON parsing fails, just keep connection open
                            pass
            except socket.timeout:
                pass
            except:
                pass
        else:
            # Not a WebSocket request, just send a basic response
            response = 'HTTP/1.1 200 OK\r\n\r\n'
            conn.send(response.encode('utf-8'))
    except:
        pass
    finally:
        conn.close()

if __name__ == '__main__':
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(("127.0.0.1", 12345))
    s.listen(5)
    while True:
        try:
            conn, addr = s.accept()
            handle_websocket_handshake(conn)
        except:
            break

