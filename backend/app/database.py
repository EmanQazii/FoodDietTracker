from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from app.config import settings

engine = create_engine(
    settings.DATABASE_URL,
    pool_size=10,          # number of persistent connections kept open
    max_overflow=20,       # extra connections allowed under high load
    pool_timeout=30,       # seconds to wait for a connection before erroring
    pool_pre_ping=True,    # checks connection is alive before using it (avoids stale connection errors)
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()