#!/bin/bash

echo "🤖 FleetOS ML Setup Script"
echo "=========================="
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3.8 or higher."
    exit 1
fi

echo "✅ Python 3 found: $(python3 --version)"
echo ""

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
    echo "✅ Virtual environment created"
else
    echo "✅ Virtual environment already exists"
fi

echo ""
echo "📥 Installing dependencies..."
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo ""
echo "✅ Dependencies installed"
echo ""

# Check if Firebase credentials exist
if [ ! -f "../serviceAccountKey.json" ]; then
    echo "⚠️  Warning: serviceAccountKey.json not found in fleet-backend/"
    echo "   ML model training requires Firebase credentials to fetch data."
    echo "   Please add your Firebase service account key before training."
    echo ""
else
    echo "✅ Firebase credentials found"
    echo ""
    
    # Ask if user wants to train models now
    read -p "🎯 Train ML models now? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "🚀 Training driver model..."
        python3 train_driver_model.py
        echo ""
        echo "🚀 Training truck model..."
        python3 train_truck_model.py
        echo ""
        echo "✅ Models trained successfully!"
    fi
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "To start the ML API server:"
echo "  cd fleet-backend/ml"
echo "  source venv/bin/activate"
echo "  python3 api.py"
echo ""
echo "The ML API will run on http://localhost:5001"
