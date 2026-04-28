#!/bin/bash

echo "🚀 Starting FleetOS Backend Services"
echo "===================================="
echo ""

# Check if Node.js backend is ready
if [ ! -d "fleet-backend/node_modules" ]; then
    echo "📦 Installing Node.js dependencies..."
    cd fleet-backend
    npm install
    cd ..
    echo "✅ Node.js dependencies installed"
    echo ""
fi

# Check if Python ML environment is ready
if [ ! -d "fleet-backend/ml/venv" ]; then
    echo "⚠️  ML environment not set up. Run: cd fleet-backend/ml && ./setup_ml.sh"
    echo ""
fi

# Start Node.js backend
echo "🟢 Starting Node.js backend on port 3000..."
cd fleet-backend
npm run dev &
BACKEND_PID=$!
cd ..

# Wait a bit for backend to start
sleep 2

# Start ML API if environment exists
if [ -d "fleet-backend/ml/venv" ]; then
    echo "🤖 Starting ML API on port 5001..."
    cd fleet-backend/ml
    source venv/bin/activate
    python3 api.py &
    ML_PID=$!
    cd ../..
    
    echo ""
    echo "✅ Both services started!"
    echo ""
    echo "📡 Node.js Backend: http://localhost:3000"
    echo "🤖 ML API: http://localhost:5001"
    echo ""
    echo "Press Ctrl+C to stop both services"
    
    # Wait for Ctrl+C
    trap "echo ''; echo '🛑 Stopping services...'; kill $BACKEND_PID $ML_PID 2>/dev/null; exit" INT
    wait
else
    echo ""
    echo "✅ Node.js backend started!"
    echo ""
    echo "📡 Backend: http://localhost:3000"
    echo "⚠️  ML API not started (environment not set up)"
    echo ""
    echo "Press Ctrl+C to stop"
    
    trap "echo ''; echo '🛑 Stopping backend...'; kill $BACKEND_PID 2>/dev/null; exit" INT
    wait
fi
