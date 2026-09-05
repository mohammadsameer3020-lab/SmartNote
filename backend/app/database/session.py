from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base


# رابط قاعدة البيانات
DATABASE_URL = "sqlite:///./smartmind.db"


# إنشاء محرك الاتصال بقاعدة البيانات
engine = create_engine(
    DATABASE_URL,
    connect_args={
        "check_same_thread": False
    }
)


# إنشاء جلسات التعامل مع قاعدة البيانات
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)


# الأب الأساسي لجميع الجداول
Base = declarative_base()