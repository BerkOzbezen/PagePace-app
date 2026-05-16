from fastapi import APIRouter

from app.api.v1.endpoints import books, friends, sessions, stats, users

api_router = APIRouter(prefix="/api/v1")
api_router.include_router(books.router)
api_router.include_router(sessions.router)
api_router.include_router(stats.router)
api_router.include_router(users.router)
api_router.include_router(friends.router)
