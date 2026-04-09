from pydantic import BaseModel


class Subject(BaseModel):
    """
    Basic subject model.

    Represents a subject or paper within the exam syllabus.
    """

    id: int
    name: str
    priority: int
    difficulty: int

