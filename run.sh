#!/bin/bash
#
# SafeEats - One-Command Development Setup
#
# This script starts both the backend API and Flutter app.
# Usage: ./run.sh
#
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🍎 SafeEats - Starting development environment...${NC}"
echo ""

# =============================================================================
# Prerequisite Checks
# =============================================================================

echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check Python
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python 3 is required but not installed.${NC}"
    echo "   Install from: https://www.python.org/downloads/"
    exit 1
fi
echo -e "  ${GREEN}✓${NC} Python 3 found: $(python3 --version)"

# Check pip
if ! command -v pip3 &> /dev/null && ! command -v pip &> /dev/null; then
    echo -e "${RED}❌ pip is required but not installed.${NC}"
    exit 1
fi
echo -e "  ${GREEN}✓${NC} pip found"

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is required but not installed.${NC}"
    echo "   Install from: https://docs.flutter.dev/get-started/install"
    exit 1
fi
echo -e "  ${GREEN}✓${NC} Flutter found: $(flutter --version | head -n 1)"

echo ""

# =============================================================================
# Backend Setup
# =============================================================================

echo -e "${YELLOW}Setting up backend...${NC}"

# Navigate to backend directory
cd backend

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "  Creating Python virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate 2>/dev/null || . venv/bin/activate

# Install dependencies
echo "  Installing Python dependencies..."
pip install -r requirements.txt -q

# Initialize database
echo "  Initializing database..."
python3 -c "from db import init_db; init_db()"

# Start backend in background
echo -e "  ${GREEN}Starting backend server...${NC}"
uvicorn app:app --host 127.0.0.1 --port 8000 &
BACKEND_PID=$!

# Return to project root
cd ..

# Wait for backend to be ready
echo "  Waiting for backend to start..."
sleep 2

# Check if backend is running
if curl -s http://127.0.0.1:8000/health > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓ Backend running at http://127.0.0.1:8000${NC}"
    echo -e "    Swagger docs: http://127.0.0.1:8000/docs"
else
    echo -e "${RED}❌ Backend failed to start${NC}"
    kill $BACKEND_PID 2>/dev/null
    exit 1
fi

echo ""

# =============================================================================
# Flutter Setup
# =============================================================================

echo -e "${YELLOW}Setting up Flutter app...${NC}"

# Get Flutter dependencies
echo "  Getting Flutter packages..."
flutter pub get

echo ""

# =============================================================================
# Run Flutter App
# =============================================================================

echo -e "${GREEN}🚀 Starting Flutter app...${NC}"
echo -e "${YELLOW}Note: Press 'q' in the Flutter console to quit both app and backend${NC}"
echo ""

# Cleanup function
cleanup() {
    echo ""
    echo -e "${YELLOW}Shutting down...${NC}"
    kill $BACKEND_PID 2>/dev/null
    echo -e "${GREEN}✓ Backend stopped${NC}"
    exit 0
}

# Set up cleanup on exit
trap cleanup EXIT INT TERM

# Run Flutter app (this will block until app is closed)
flutter run

# Cleanup will be called automatically on exit