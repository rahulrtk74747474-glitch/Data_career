FROM python:3.12-slim
RUN python -m pip install --no-cache-dir 'pandas>=2.2,<3'
WORKDIR /
USER 65534:65534
CMD ["python", "-I", "/worker.py"]
