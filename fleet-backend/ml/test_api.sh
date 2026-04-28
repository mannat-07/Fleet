#!/bin/bash

echo "🧪 Testing FleetOS ML API"
echo "========================"
echo ""

ML_URL="http://localhost:5001"

# Test health endpoint
echo "1️⃣  Testing health endpoint..."
curl -s "$ML_URL/health" | python3 -m json.tool
echo ""
echo ""

# Test driver prediction
echo "2️⃣  Testing driver prediction..."
curl -s -X POST "$ML_URL/predict/driver" \
  -H "Content-Type: application/json" \
  -d '{
    "safety_score": 92,
    "fuel_efficiency": 6.2,
    "on_time_delivery_rate": 88,
    "alert_count": 2,
    "experience_years": 5,
    "trips_completed": 150
  }' | python3 -m json.tool
echo ""
echo ""

# Test truck prediction
echo "3️⃣  Testing truck prediction..."
curl -s -X POST "$ML_URL/predict/truck" \
  -H "Content-Type: application/json" \
  -d '{
    "maintenance_score": 95,
    "fuel_efficiency": 5.8,
    "breakdown_count": 1,
    "age_years": 3,
    "total_trips": 200,
    "avg_load_capacity_used": 82
  }' | python3 -m json.tool
echo ""
echo ""

echo "✅ Tests complete!"
