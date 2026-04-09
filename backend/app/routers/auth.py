from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import timedelta

from app.db.database import get_db
from app.db.models import User
from app.schemas import UserCreate, UserOut, Token, UserUpdate, TokenRefreshRequest
from app.core.security import (
    get_password_hash, 
    verify_password, 
    create_access_token, 
    create_refresh_token,
    ACCESS_TOKEN_EXPIRE_MINUTES,
    SECRET_KEY,
    ALGORITHM
)
from app.core.deps import get_current_user
import jwt

router = APIRouter()

@router.post("/signup", response_model=UserOut)
def signup(user_in: UserCreate, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == user_in.email).first()
    if user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    new_user = User(
        name=user_in.name,
        email=user_in.email,
        hashed_password=get_password_hash(user_in.password),
        daily_study_hours=user_in.daily_study_hours
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@router.post("/login", response_model=Token)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == form_data.username).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token = create_access_token(data={"sub": user.email})
    refresh_token = create_refresh_token(data={"sub": user.email})
    
    # Store refresh token in DB
    user.refresh_token = refresh_token
    db.commit()
    
    return {
        "access_token": access_token, 
        "refresh_token": refresh_token,
        "token_type": "bearer"
    }

@router.post("/refresh", response_model=Token)
def refresh_token(refresh_in: TokenRefreshRequest, db: Session = Depends(get_db)):
    try:
        payload = jwt.decode(refresh_in.refresh_token, SECRET_KEY, algorithms=[ALGORITHM])
        if payload.get("type") != "refresh":
            raise HTTPException(status_code=401, detail="Invalid token type")
        email = payload.get("sub")
        if not email:
            raise HTTPException(status_code=401, detail="Invalid token payload")
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Could not validate refresh token")
    
    user = db.query(User).filter(User.email == email).first()
    if not user or user.refresh_token != refresh_in.refresh_token:
        raise HTTPException(status_code=401, detail="Refresh token expired or revoked")
    
    access_token = create_access_token(data={"sub": user.email})
    # Optional: Rotate refresh token
    new_refresh_token = create_refresh_token(data={"sub": user.email})
    user.refresh_token = new_refresh_token
    db.commit()
    
    return {
        "access_token": access_token,
        "refresh_token": new_refresh_token,
        "token_type": "bearer"
    }

@router.get("/me", response_model=UserOut)
def read_users_me(current_user: User = Depends(get_current_user)):
    return current_user

@router.put("/me", response_model=UserOut)
def update_user_me(user_update: UserUpdate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if user_update.daily_study_hours is not None:
        current_user.daily_study_hours = user_update.daily_study_hours
    if user_update.name is not None:
        current_user.name = user_update.name
    import json
    if user_update.weak_subjects is not None:
        current_user.weak_subjects = json.dumps(user_update.weak_subjects)
        current_user.target_year = user_update.target_year
        
    db.commit()
    db.refresh(current_user)
    return current_user
from app.schemas import UserCreate, UserOut, Token, UserUpdate, UserPreferencesRequest

# ... (keep existing code)

@router.post("/preferences", response_model=UserOut)
def update_preferences(prefs: UserPreferencesRequest, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if prefs.study_style is not None:
        current_user.study_style = prefs.study_style
    if prefs.focus_level is not None:
        current_user.focus_level = prefs.focus_level
    if prefs.revision_preference is not None:
        current_user.revision_preference = prefs.revision_preference
    if prefs.current_affairs_weight is not None:
        current_user.current_affairs_weight = prefs.current_affairs_weight
        
    db.commit()
    db.refresh(current_user)
    return current_user

@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
def delete_user_account(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    db.delete(current_user)
    db.commit()
    return None

from app.db.models import StudyBlock, DailyReport
from app.schemas import ClearDataResponse

@router.post("/clear_data", response_model=ClearDataResponse)
def clear_study_data(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    db.query(StudyBlock).filter(StudyBlock.user_id == current_user.id).delete()
    db.query(DailyReport).filter(DailyReport.user_id == current_user.id).delete()
    db.commit()
    return {"status": "success", "message": "All study blocks and daily reports have been cleared."}
