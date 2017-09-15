
FROM mhart/alpine-node:4
MAINTAINER NIUWEIFNEG  <niuweifneg@cloudwalk.cn>
WORKDIR /src

# If you have native dependencies, you'll need extra tools
RUN apk add --update make gcc g++ \
&& npm install -g npm \
&& npm install -g yo generator-hubot \
&& adduser hubot -h /home/hubot -D -s /bin/sh

ENV HOME /home/hubot
USER hubot
WORKDIR /home/hubot

RUN echo "No" | yo hubot --adapter mattermost --name matterbot --defaults
COPY external-scripts.json /home/hubot/external-scripts.json
#COPY jenkins.coffee scripts/
RUN npm install hubot-jenkins hubot-wit --save

CMD ["-a", "mattermost"]
ENTRYPOINT ["./bin/hubot"]

EXPOSE 8080
