# Memory Leak Fix - Verification and Testing Plan

## Overview
This document provides a comprehensive, step-by-step plan to verify that the ONNX Runtime memory leak has been successfully resolved in the Sign Language Translator backend.

---

## Prerequisites

### Required Tools
1. **Visual Studio 2022** (or later) with diagnostic tools
2. **dotMemory** by JetBrains (alternative to Visual Studio profiler)
3. **.NET 8 SDK** installed
4. **Docker Desktop** (if testing in containerized environment)

### Test Environment Setup
- Clean local environment
- Ensure no other heavy applications are running
- Close unnecessary browser tabs and applications
- Have at least 4GB of free RAM available

---

## 🧪 Test Procedure

### Phase 1: Baseline Memory Measurement (BEFORE Fix)

#### Step 1.1: Checkout the Original Code
```bash
# Switch to the branch with the memory leak issue
git checkout origin/main
# Or use the commit before the fix
```

#### Step 1.2: Start the Application
```bash
cd backend/GraduationProjectWebApplication
dotnet run --configuration Release
```

#### Step 1.3: Take Initial Memory Snapshot
1. Open **Visual Studio**
2. Navigate to **Debug > Performance Profiler** (Alt+F2)
3. Select **.NET Object Allocation Tracking** and **Memory Usage**
4. Click **Start**
5. Take Snapshot #1 (Baseline - Application Started)

#### Step 1.4: Simulate User Activity (Camera Session)
1. Open your frontend application
2. Start the camera and begin translating signs
3. Allow the application to process **50-100 frames** (about 30 seconds of activity)
4. Take Snapshot #2 (During Active Use)

#### Step 1.5: Stop User Activity
1. Close the camera in the frontend
2. Wait for **30 seconds** (no requests should be made)
3. Force garbage collection:
   - In Visual Studio Diagnostic Tools, click "Force GC"
   - Or use the memory profiler's collection button
4. Take Snapshot #3 (After Session + GC)

#### Step 1.6: Record Baseline Results
Document the following from Snapshot #3:
- **Total Managed Memory**: _____ MB
- **Total Process Memory**: _____ MB
- **Number of InferenceSession instances**: _____ (search in heap objects)
- **Number of DenseTensor<float> instances**: _____

**Expected Result (BEFORE FIX):** Memory should remain elevated, multiple InferenceSession objects should exist in memory.

---

### Phase 2: Verification After Fix

#### Step 2.1: Apply the Fix
```bash
# Switch to the branch with the fix
git checkout DEV
# Or apply the fix manually
```

#### Step 2.2: Clean and Rebuild
```bash
cd backend/GraduationProjectWebApplication
dotnet clean
dotnet build --configuration Release
dotnet run --configuration Release
```

#### Step 2.3: Verify Singleton Initialization
Check the console output for:
```
[ModelService] ONNX InferenceSession initialized as SINGLETON at [timestamp]
```
This should appear **only ONCE** when the application starts.

#### Step 2.4: Start Profiling Session
1. Open **Visual Studio Performance Profiler**
2. Select **.NET Object Allocation Tracking** and **Memory Usage**
3. Click **Start**
4. Take Snapshot #1 (Baseline - Application Started with Fix)

#### Step 2.5: Simulate Multiple User Sessions
**Session 1:**
1. Open frontend, start camera
2. Process 50-100 frames (30 seconds)
3. Close camera
4. Take Snapshot #2 (After Session 1)

**Force GC and Wait:**
- Click "Force GC" in diagnostic tools
- Wait 10 seconds
- Take Snapshot #3 (After Session 1 + GC)

**Session 2:**
1. Open camera again
2. Process another 50-100 frames (30 seconds)
3. Close camera
4. Take Snapshot #4 (After Session 2)

**Final Check:**
- Force GC again
- Wait 10 seconds
- Take Snapshot #5 (After Session 2 + GC - Final)

#### Step 2.6: Analyze Results

Compare Snapshots #3 and #5 for:

| Metric | Snapshot #3 | Snapshot #5 | Expected Change |
|--------|-------------|-------------|-----------------|
| Total Managed Memory | _____ MB | _____ MB | Minimal increase (< 5%) |
| Total Process Memory | _____ MB | _____ MB | Minimal increase (< 5%) |
| InferenceSession Count | 1 | 1 | No change |
| DenseTensor Count | 0 | 0 | No change (all disposed) |

**Expected Result (AFTER FIX):** 
- Memory should return to near-baseline after GC
- Only **ONE** InferenceSession should exist throughout all sessions
- No DenseTensor objects should persist after GC

---

### Phase 3: Long-Running Stress Test

#### Step 3.1: Extended Load Test
Run the following test to simulate multiple users over an extended period:

```bash
# Use a load testing tool or script to send continuous requests
# for 10-15 minutes, then stop and observe memory behavior
```

#### Step 3.2: Monitor Memory Over Time
1. In Visual Studio, switch to **Memory Usage** graph view
2. Observe the "sawtooth" pattern:
   - Memory increases during request processing
   - Memory drops after GC collection
   - Peak levels should remain stable, not continuously increasing

**Expected Result:** 
- Memory graph should show a stable sawtooth pattern
- Peak memory should stabilize after 2-3 minutes
- No continuous upward trend

---

### Phase 4: Comparative Analysis

#### Step 4.1: Create Comparison Report

| Measurement | Before Fix | After Fix | Improvement |
|-------------|------------|-----------|-------------|
| Memory after 1 session + GC | _____ MB | _____ MB | _____ MB saved |
| Memory after 2 sessions + GC | _____ MB | _____ MB | _____ MB saved |
| InferenceSession instances | Multiple | 1 | N/A |
| Memory growth per session | _____ MB | ~0 MB | Fixed ✅ |

---

## 🔬 Advanced Verification (Optional)

### Using dotMemory (JetBrains)

1. **Install dotMemory**: Download from JetBrains website
2. **Start Profiling**:
   ```bash
   dotmemory attach <process-id>
   ```
3. **Take snapshots** following the same procedure as Phase 1-2
4. **Use dotMemory's "Compare Snapshots" feature** to see exact object differences

### Using Diagnostic CLI Commands

```bash
# Install diagnostic tools
dotnet tool install --global dotnet-counters
dotnet tool install --global dotnet-gcdump

# Monitor GC memory in real-time
dotnet-counters monitor --process-id <pid> System.Runtime

# Capture heap dump for analysis
dotnet-gcdump collect --process-id <pid>
```

---

## ✅ Success Criteria

The memory leak fix is confirmed successful if:

1. ✅ Only **ONE** InferenceSession exists throughout the application lifetime
2. ✅ Memory returns to near-baseline (±5%) after user sessions end and GC runs
3. ✅ No continuous memory growth over multiple user sessions
4. ✅ DenseTensor objects are properly disposed (count returns to 0 after GC)
5. ✅ Console log shows singleton initialization message only once
6. ✅ Long-running stress test shows stable memory pattern (sawtooth, not upward trend)

---

## 🚨 Troubleshooting

### If Memory Still Doesn't Decrease:

**Check 1:** Verify singleton registration
```csharp
// In Program.cs, ensure you have:
builder.Services.AddSingleton<IModelService, ModelService>();
// NOT AddScoped or AddTransient
```

**Check 2:** Verify IDisposable implementation
- Ensure ModelService implements IDisposable
- Ensure _onnxSession.Dispose() is called in Dispose method

**Check 3:** Force application shutdown and restart
- Sometimes the profiler holds references
- Completely restart Visual Studio and the application

**Check 4:** Check for other references
```csharp
// In ModelRunner method, ensure you're using:
using var results = await Task.Run(() => _onnxSession.Run(inputs));
// The 'using' keyword ensures disposal
```

---

## 📊 Reporting Results

After completing verification, document:

1. **Screenshots** of memory snapshots (before/after)
2. **Memory comparison table** with actual numbers
3. **Heap object count** for InferenceSession and DenseTensor
4. **Performance impact** (if any) - measure average request time
5. **Conclusion** - confirm the fix resolves the issue

---

## 📝 Notes

- Always use **Release** configuration for accurate memory measurements
- Allow GC time to work (10-30 seconds after stopping requests)
- Multiple GC passes may be needed for full cleanup
- Large objects (like ML models) are in Gen 2 heap and require full GC collection
- The singleton pattern also improves performance by eliminating model load overhead

---

## References

- [Visual Studio Memory Profiling](https://learn.microsoft.com/en-us/visualstudio/profiling/memory-usage)
- [ONNX Runtime Best Practices](https://onnxruntime.ai/docs/performance/tune-performance.html)
- [.NET Garbage Collection](https://learn.microsoft.com/en-us/dotnet/standard/garbage-collection/)
