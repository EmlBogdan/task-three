FROM ollama/ollama

RUN ollama serve
RUN ollama pull tinyllama
ENV OLLAMA_HOST=0.0.0.0/0
EXPOSE 11434
