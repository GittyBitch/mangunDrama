import platform
import sys
import os
import json

import fastapi
import mangum

from fastapi import FastAPI
from mangum import Mangum
import pydantic

def get_library_versions():
    return  {
        "Python Version": sys.version,
        "Python Executable": sys.executable,
        "Architecture": platform.architecture(),
        "System": platform.system(),
        "Machine": platform.machine(),
        "Processor": platform.processor(),
        "Fastapi": fastapi.__version__,
        "Pydantic": pydantic.__version__}
    
app = FastAPI()
handler = Mangum(app)

@app.get("/")
def root():
    return get_library_versions()
    
