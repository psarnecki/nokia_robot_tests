# EPC Network Robot Tests

Automated tests for the EPC simulator using Robot Framework.

## Setup Instructions

### 1. Python Environment
Install Robot Framework and the necessary library for REST API communication:
```bash
pip install robotframework robotframework-requests
```

## 2. EPC Simulator (Docker)
To run the simulator required for the tests:

**Preliminary step:**

``` Make sure that Docker Desktop is launched and the engine is in the "Running" state. ```

**Load the image:**
```bash
docker load -i epc-simulator.tar
```

**Run the container:**
```bash
docker run -p 8000:8000 epc-simulator:1.0.0
```

**Verify API:**
```bash
http://127.0.0.1:8000/docs
```

## 3. Running Tests
**Execute the example test suite:**

```bash
robot tests/example_test.robot
```
