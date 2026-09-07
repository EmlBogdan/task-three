FROM ollama/ollama:latest

RUN nohup ollama serve & sleep 5 && ollama pull tinyllama

