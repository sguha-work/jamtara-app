FROM ubuntu:latest
RUN apt-get update
RUN apt-get install python3 -y
RUN apt-get install python3-pip -y
RUN pip3 -v
RUN pip3 install --upgrade pip 
RUN pip3 install firebase-admin
RUN pip3 install flask
COPY . . 
EXPOSE 5000
CMD ["python3", "app.py"]

# to build the image run following command
# docker build -t python_benexpreppy .
# to run the container use following commands
# docker run -d -p 5000:5000 python_benexpreppy