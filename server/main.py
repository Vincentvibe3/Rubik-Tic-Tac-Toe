import asyncio

from uuid import uuid4

from fastapi import FastAPI, WebSocketDisconnect
from fastapi import WebSocket
from asyncio import Lock
from argon2 import PasswordHasher
from pydantic import BaseModel


app = FastAPI()
ph = PasswordHasher()

class Room:
    
    def __init__(self, name:str, socket:WebSocket, password_hash:str=None):
        self.id = str(uuid4())
        self.name = name
        self.host = socket
        self.password_hash = password_hash
        self.peer = None
        self.peerSetEvent = asyncio.Event()
        self.lock = Lock()
        self.closed = False
    
    async def is_closed(self):
        async with self.lock:
            return self.closed

    async def close(self):
        async with self.lock:
            self.closed = True

    async def set_peer(self, socket:WebSocket):
        async with self.lock:
            self.peer = socket
    
    async def get_peer(self):
        async with self.lock:
            return self.peer

    async def is_password_protected(self):
        async with self.lock:
            return self.password_hash is not None
    
    async def verify_password(self, password:str):
        async with self.lock:
            if self.password_hash is None:
                return True
            try:
                return ph.verify(self.password_hash, password)
            except:
                return False

class RoomInfo(BaseModel):
    name:str
    room_id: str
    is_password_protected:bool
        

class ActiveRooms:
    
    def __init__(self):
        self.room_map = {}
        self.lock = Lock()
    
    async def insert(self, room:Room):
        async with self.lock:
            self.room_map[room.id] = room
    
    async def get_room_info(self):
        async with self.lock:
            return [RoomInfo(name=x.name, room_id=x.id, is_password_protected=await x.is_password_protected()) for x in self.room_map.values()]
    
    async def disconnect_room(self, room):
        async with self.lock:
            if room.id in self.room_map:
                return self.room_map.pop(room.id)
            
    async def remove_room(self, room_id:str, password:str):
        async with self.lock:
            if room_id in self.room_map:
                if await self.room_map[room_id].verify_password(password):
                    return self.room_map.pop(room_id), True
            else:
                return None, False
        return None, True

activeRooms = ActiveRooms()

async def handle_client(websocket:WebSocket, room:Room, is_host:bool=False):
    if not is_host:
        #game ready
        peer = room.host
        await room.set_peer(websocket)
        try:
            await room.host.send_json({"id": 0, "payload":{}})
        except WebSocketDisconnect:
            await activeRooms.disconnect_room(room)
            websocket.close(3004, "disconnected")
            return
        try:
            await websocket.send_json({"id": 0, "payload":{}})
        except WebSocketDisconnect:
            await activeRooms.disconnect_room(room)
            if not await room.is_closed():
                await room.close()
                await peer.close(3004, "disconnected")
            return
    else:
        peer = await room.get_peer()
        try:
            await websocket.send_json({"id": 1, "payload":{"id":room.id}})
        except WebSocketDisconnect:
            await activeRooms.disconnect_room(room)
            if peer is not None:
                if not await room.is_closed():
                    await room.close()
                    await peer.close(3004, "disconnected")
            return
        

    while True:
        # forward messages
        try:
            data = await websocket.receive_json()
        except WebSocketDisconnect:
            if peer is None and is_host:
                peer = await room.get_peer()
            if peer is not None:
                if not await room.is_closed():
                    await room.close()
                    await peer.close(3004, "disconnected")
            else:
                await room.close()
                await activeRooms.disconnect_room(room)
            return
        if peer is None and is_host:
            peer = await room.get_peer()
        if peer is None:
            continue 
        try:
            await peer.send_json(data)
        except WebSocketDisconnect:
            await websocket.close(3004, "disconnected")
            return

@app.websocket("/connect")
async def new_client(websocket:WebSocket):
    await websocket.accept()
    try:
        data = await websocket.receive_json()
        if "id" not in data:
            websocket.close(3001, "missing data")
            return
        if data["id"] == 0:
            if "payload" not in data or "name" not in data["payload"]:
                await websocket.close(3001, "missing data")
                return
            payload = data["payload"]
            password_hash = None
            if "password" in payload:
                password_hash = ph.hash(payload["password"])
                
            new_room = Room(payload["name"], websocket, password_hash)
            await activeRooms.insert(new_room)
            await handle_client(websocket, new_room, True)
        elif data["id"] == 1:
            if "payload" not in data or "room_id" not in data["payload"]:
                await websocket.close(3001, "missing data")
                return
            payload = data["payload"]
            room_id = payload["room_id"]
            password = None
            if "password" in payload:
                password = payload["password"]
            room, room_exists = await activeRooms.remove_room(room_id, password)
            if room is None and room_exists:
                await websocket.close(3002, "invalid password")
                return
            elif room is None and not room_exists:
                await websocket.close(3003, "room does not exist")
                return
            await handle_client(websocket, room)
    except WebSocketDisconnect:
        pass

@app.get("/rooms")
async def get_rooms():
    room_info = await activeRooms.get_room_info()
    return room_info