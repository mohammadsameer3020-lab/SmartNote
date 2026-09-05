# app/database/base.py

from app.database.session import Base

# استيراد جميع الـ Models
# حتى يتعرف SQLAlchemy عليها ويقوم بإنشاء الجداول

from app.models.user import User