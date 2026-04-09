import { GoogleGenAI, Type } from "@google/genai";

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY || '' });

export const generateStudySchedule = async (examType: string, examDate: string, dailyHours: number, subjects: string[], profile?: any) => {
  const behavioralContext = profile ? `
    Focus Level: ${profile.focus_level || 'Medium'}
    Distraction Level: ${profile.distraction_level || 'Low'}
    Weak Subjects: ${profile.weak_subjects || 'None'}
    Strong Subjects: ${profile.strong_subjects || 'None'}
  ` : '';

  const response = await ai.models.generateContent({
    model: "gemini-3-flash-preview",
    contents: `Generate a daily study schedule for ${examType} exam on ${examDate}. 
    Available daily hours: ${dailyHours}. 
    Subjects to cover: ${subjects.join(', ')}.
    Behavioral Context: ${behavioralContext}
    
    Instructions:
    - Allocate more time to weak subjects.
    - Schedule difficult topics during peak focus hours (if focus level is high).
    - Include short breaks if distraction level is high.
    - Return a JSON array of study blocks for the next 7 days.
    Each block should have: subject, topic, startTime (ISO string), durationMinutes, status (pending).`,
    config: {
      responseMimeType: "application/json",
      responseSchema: {
        type: Type.ARRAY,
        items: {
          type: Type.OBJECT,
          properties: {
            subject: { type: Type.STRING },
            topic: { type: Type.STRING },
            startTime: { type: Type.STRING },
            durationMinutes: { type: Type.NUMBER },
            status: { type: Type.STRING }
          },
          required: ["subject", "topic", "startTime", "durationMinutes", "status"]
        }
      }
    }
  });

  return JSON.parse(response.text);
};

export const getBehavioralInsight = async (profile: any, recentPerformance: any[]) => {
  const response = await ai.models.generateContent({
    model: "gemini-3-flash-preview",
    contents: `Analyze the student's profile and recent performance:
    Profile: ${JSON.stringify(profile)}
    Recent Performance: ${JSON.stringify(recentPerformance)}
    
    Provide a concise, professional behavioral insight (max 2 sentences) and a specific action point for today.
    Return JSON with fields: insight, actionPoint.`,
    config: {
      responseMimeType: "application/json",
      responseSchema: {
        type: Type.OBJECT,
        properties: {
          insight: { type: Type.STRING },
          actionPoint: { type: Type.STRING }
        },
        required: ["insight", "actionPoint"]
      }
    }
  });
  return JSON.parse(response.text);
};

export const generateMockTest = async (subject: string, difficulty: string = 'medium') => {
  const response = await ai.models.generateContent({
    model: "gemini-3-flash-preview",
    contents: `Generate a UPSC-style mock test for the subject: ${subject}. 
    Difficulty level: ${difficulty}.
    Return a JSON array of 5 multiple-choice questions.
    Each question should have: question, options (array of 4 strings), correctAnswer (index 0-3), and explanation.`,
    config: {
      responseMimeType: "application/json",
      responseSchema: {
        type: Type.ARRAY,
        items: {
          type: Type.OBJECT,
          properties: {
            question: { type: Type.STRING },
            options: { 
              type: Type.ARRAY,
              items: { type: Type.STRING }
            },
            correctAnswer: { type: Type.NUMBER },
            explanation: { type: Type.STRING }
          },
          required: ["question", "options", "correctAnswer", "explanation"]
        }
      }
    }
  });

  return JSON.parse(response.text);
};

export const getBacklogRecoveryPlan = async (missedTasks: any[]) => {
  const response = await ai.models.generateContent({
    model: "gemini-3-flash-preview",
    contents: `The student missed the following tasks: ${JSON.stringify(missedTasks)}. 
    Suggest a backlog recovery plan to redistribute these tasks into the next 3 days without overwhelming the student.
    Return a list of suggested adjustments in JSON format.`,
    config: {
      responseMimeType: "application/json"
    }
  });
  return JSON.parse(response.text);
};

export const getMotivationalQuote = async (character?: string) => {
  const prompt = character 
    ? `Give me a motivational quote for a student preparing for a tough exam, inspired by the character ${character}.`
    : "Give me a powerful motivational quote for a competitive exam aspirant.";
    
  const response = await ai.models.generateContent({
    model: "gemini-3-flash-preview",
    contents: prompt
  });
  return response.text;
};
