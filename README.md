# Food Tracker — AI Based Food Recognition & Dietary Tracking

## Requirements
- Python **3.11** (TensorFlow does not support Python 3.12+)
- PostgreSQL
- Flutter SDK

---

## Backend Setup

### 1. Clone the repository
\`
git clone <your-repo-url>
\`

### 2. Navigate to backend folder
\`
cd backend
\`

### 3. Create virtual environment with Python 3.11
\`
python -m venv venv
\`

### 4. Activate virtual environment

**Windows:**
\`
venv\Scripts\activate
\`

**Mac/Linux:**
\`
source venv/bin/activate
\`

### 5. Install dependencies
\`
pip install -r requirements.txt
\`

### 6. Create .env file in backend/ folder
\`
DATABASE_URL=postgresql://postgres:yourpassword@localhost:5432/foodtracker
SECRET_KEY=your-secret-key
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
\`

### 7. Create PostgreSQL database
Create a database named `foodtracker` in pgAdmin or psql.

### 8. Run the server
uvicorn main:app --reload

---

## ML Model
| Property | Value |
|---|---|
| Base Model | MobileNetV2 |
| Custom Layer | ChannelAttention |
| Dataset | Food-101 |
| Classes | 34 food categories |
| Val Accuracy | ~76% |
| Model File | best_finetuned_v2.h5 |

---

## Project Structure
\`
food-tracker/
├── backend/
│   ├── app/
│   │   ├── config.py
│   │   └── database.py
│   ├── routes/
│   ├── models/
│   ├── services/
│   │   └── calorie_mapper.py
│   ├── ml/
│   │   ├── class_labels.json
│   │   └── saved_model/
│   ├── main.py
│   ├── requirements.txt
│   └── .env
├── frontend/
├── .gitignore
└── README.md
\`

---

## Notes
> Never commit your `.env` file
> Model `.h5` files are excluded from git via `.gitignore`
> Always use Python 3.11 strictly for this project