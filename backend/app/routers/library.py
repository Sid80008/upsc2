from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List
from app.db.database import get_db
from app.db.models import StudyBlock, User, Folder, KnowledgeAsset
from app.schemas import SubjectStats, SubjectAddRequest, FolderCreate, FolderOut, KnowledgeAssetCreate, KnowledgeAssetOut
from app.core.deps import get_current_user
import json

router = APIRouter()

@router.get("/subjects")
def get_library_subjects(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    # 1. Get stats from StudyBlocks
    stats = db.query(
        StudyBlock.subject,
        func.sum(StudyBlock.time_spent_minutes).label("total_minutes"),
        func.max(StudyBlock.date).label("last_date")
    ).filter(
        StudyBlock.user_id == current_user.id,
        StudyBlock.status == "completed"
    ).group_by(StudyBlock.subject).all()
    
    stats_map = {s.subject: s for s in stats}
    
    # 2. Get all defined subjects from user profile
    try:
        covered_data = json.loads(current_user.covered_subjects) if current_user.covered_subjects else []
    except:
        covered_data = []
    
    results = []
    seen_subjects = set()
    
    # Process covered_data (can be strings or dicts)
    for entry in covered_data:
        if isinstance(entry, str):
            name = entry
            priority = "medium"
        else:
            name = entry.get("name", "Unknown")
            priority = entry.get("priority", "medium")
        
        seen_subjects.add(name)
        s = stats_map.get(name)
        hours = (s.total_minutes / 60) if s else 0
        strength = min(int(hours * 10), 100)
        
        results.append({
            "subject_name": name,
            "total_hours_studied": round(hours, 1),
            "last_studied_date": s.last_date if s else None,
            "strength_score": strength,
            "priority": priority
        })
    
    # Add any completed subjects that weren't in covered_subjects (failsafe)
    for name, s in stats_map.items():
        if name not in seen_subjects:
            hours = s.total_minutes / 60
            results.append({
                "subject_name": name,
                "total_hours_studied": round(hours, 1),
                "last_studied_date": s.last_date,
                "strength_score": min(int(hours * 10), 100),
                "priority": "medium"
            })
            
    return results

@router.post("/add_subject")
def add_library_subject(
    payload: SubjectAddRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        current_subjects = json.loads(current_user.covered_subjects) if current_user.covered_subjects else []
    except:
        current_subjects = []
    
    # Check if exists
    exists = False
    for s in current_subjects:
        if isinstance(s, str):
            if s == payload.subject_name: exists = True
        elif s.get("name") == payload.subject_name:
            exists = True
            
    if not exists:
        new_entry = {
            "name": payload.subject_name,
            "topic": payload.topic,
            "time_period": payload.time_period,
            "priority": payload.priority
        }
        current_subjects.append(new_entry)
        current_user.covered_subjects = json.dumps(current_subjects)
        db.commit()
    
    return {"status": "success", "message": f"Subject {payload.subject_name} added to library."}

@router.get("/folders", response_model=List[FolderOut])
def get_folders(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return db.query(Folder).filter(Folder.user_id == current_user.id).all()

@router.post("/folders", response_model=FolderOut)
def create_folder(payload: FolderCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    new_folder = Folder(user_id=current_user.id, **payload.model_dump())
    db.add(new_folder)
    db.commit()
    db.refresh(new_folder)
    return new_folder

@router.get("/assets", response_model=List[KnowledgeAssetOut])
def get_assets(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return db.query(KnowledgeAsset).filter(KnowledgeAsset.user_id == current_user.id).order_by(KnowledgeAsset.created_at.desc()).all()

@router.post("/assets/link", response_model=KnowledgeAssetOut)
def link_asset(payload: KnowledgeAssetCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    # Used for non-file assets like bookmarks or manual notes
    new_asset = KnowledgeAsset(user_id=current_user.id, **payload.model_dump())
    db.add(new_asset)
    db.commit()
    db.refresh(new_asset)
    return new_asset

@router.post("/upload")
async def upload_asset(
    folder_id: int = None,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Determine type
    asset_type = "document"
    if file.filename.endswith(('.png', '.jpg', '.jpeg')):
        asset_type = "image"
    elif file.filename.endswith('.pdf'):
        asset_type = "pdf"
        
    # Simulate saving to storage
    fake_url = f"/assets/{file.filename}"
    
    # Save metadata to database
    new_asset = KnowledgeAsset(
        user_id=current_user.id,
        folder_id=folder_id,
        title=file.filename,
        asset_type=asset_type,
        status="Analyzed", # Pre-analyzed for demo purposes
        content_url=fake_url
    )
    db.add(new_asset)
    db.commit()
    db.refresh(new_asset)
        
    return {
        "status": "success",
        "asset": {
            "id": new_asset.id,
            "filename": new_asset.title,
            "type": new_asset.asset_type,
            "url": new_asset.content_url
        }
    }
