import http from 'k6/http';
import {SharedArray} from 'k6/data'
import {check} from 'k6';
import {sleep} from 'k6';

const config = JSON.parse(open('./config.json'));

const requests = SharedArray('test-data', function () {
  let raw_requests = JSON.parse(open("./requests.json")).requests;

  for (let request of raw_requests) {
    request['body'] = JSON.parse(open(request.body_file));
    request['response'] = JSON.parse(open(request.response_file));
  }
  return raw_requests;
});

export const options = {
  // httpDebug: 'full',
  thresholds: {
    http_req_duration: ["p(95)<" + config.thresholds.http_req_duration], // 95% of requests should be below 200ms
  },
  stages: [

    {duration: '2m', target: 100}, // below normal load

    {duration: '5m', target: 100},

    {duration: '2m', target: 200}, // normal load

    {duration: '5m', target: 200},

    {duration: '2m', target: 300}, // around the breaking point

    {duration: '5m', target: 300},

    {duration: '2m', target: 400}, // beyond the breaking point

    {duration: '5m', target: 400},

    {duration: '10m', target: 0}, // scale down. Recovery stage.

  ],
};

export default function () {
  const req = requests[Math.floor(Math.random() * requests.length)];
  const params = {
    headers: req.headers
  };

  // creation of the checks
  var checks = {};
  for (let validation of config.validations) {
    switch (validation.type) {
      case "status_code":
        checks['is status code ' + validation.value] = (r) => r.status === 200;
        break;

      case "response_body":
        checks['verify response body'] = (r) => r.body.includes(JSON.stringify(req.response));
        break;
    }
  }

  const res = http.post(config.url, JSON.stringify(req.body), params);
  check(res, checks);
  sleep(1);
}
