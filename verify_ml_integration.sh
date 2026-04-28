#!/bin/bash

echo "🔍 Verifying ML Integration"
echo "============================"
echo ""

# Check backend files
echo "✓ Checking backend files..."
files=(
    "fleet-backend/src/routes/ml.js"
    "fleet-backend/src/controllers/mlController.js"
    "fleet-backend/src/services/mlService.js"
    "fleet-backend/ml/api.py"
    "fleet-backend/ml/train_driver_model.py"
    "fleet-backend/ml/train_truck_model.py"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file (missing)"
    fi
done

echo ""
echo "✓ Checking Flutter files..."
flutter_files=(
    "fleet_manager/lib/screens/ml_recommendations_screen.dart"
)

for file in "${flutter_files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file (missing)"
    fi
done

echo ""
echo "✓ Checking metrics endpoints..."

# Check driver metrics
if grep -q "updateDriverMetrics" fleet-backend/src/routes/drivers.js; then
    echo "  ✅ Driver metrics endpoint"
else
    echo "  ❌ Driver metrics endpoint (missing)"
fi

# Check truck metrics
if grep -q "updateTruckMetrics" fleet-backend/src/routes/trucks.js; then
    echo "  ✅ Truck metrics endpoint"
else
    echo "  ❌ Truck metrics endpoint (missing)"
fi

# Check ML routes registered
if grep -q "mlRoutes" fleet-backend/src/app.js; then
    echo "  ✅ ML routes registered in app.js"
else
    echo "  ❌ ML routes not registered"
fi

echo ""
echo "✓ Checking Flutter API methods..."

# Check Flutter API service
if grep -q "updateDriverMetrics" fleet_manager/lib/services/api_service.dart; then
    echo "  ✅ updateDriverMetrics"
else
    echo "  ❌ updateDriverMetrics (missing)"
fi

if grep -q "updateTruckMetrics" fleet_manager/lib/services/api_service.dart; then
    echo "  ✅ updateTruckMetrics"
else
    echo "  ❌ updateTruckMetrics (missing)"
fi

if grep -q "predictDriverScore" fleet_manager/lib/services/api_service.dart; then
    echo "  ✅ predictDriverScore"
else
    echo "  ❌ predictDriverScore (missing)"
fi

if grep -q "getDriverRecommendations" fleet_manager/lib/services/api_service.dart; then
    echo "  ✅ getDriverRecommendations"
else
    echo "  ❌ getDriverRecommendations (missing)"
fi

echo ""
echo "✓ Checking default metrics in services..."

# Check driver service has default metrics
if grep -q "safety_score.*85" fleet-backend/src/services/driverService.js; then
    echo "  ✅ Driver default metrics initialized"
else
    echo "  ❌ Driver default metrics (missing)"
fi

# Check truck service has default metrics
if grep -q "maintenance_score.*90" fleet-backend/src/services/truckService.js; then
    echo "  ✅ Truck default metrics initialized"
else
    echo "  ❌ Truck default metrics (missing)"
fi

echo ""
echo "✓ Checking ML dashboard integration..."

if grep -q "MLRecommendationsScreen" fleet_manager/lib/screens/dashboard_screen.dart; then
    echo "  ✅ ML screen imported in dashboard"
else
    echo "  ❌ ML screen not imported"
fi

echo ""
echo "=============================="
echo "✅ Verification complete!"
echo ""
echo "Next steps:"
echo "1. Start backend: ./start_backend.sh"
echo "2. Setup ML: cd fleet-backend/ml && ./setup_ml.sh"
echo "3. Start Flutter: cd fleet_manager && flutter run -d chrome"
