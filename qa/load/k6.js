import http from "k6/http";
import { check, sleep } from "k6";

export let options = {
    stages: [
        { duration: "30s", target: 1000 },
    ]
};

export default function() {
    let res = http.get("https://staging.gitlab.com/gitlab-qa-perf-sandbox-1ac92fcc40c4cfe1/my-test-project-1d8efe186f9da839/merge_requests/31");
    check(res, {
        "status was 200": (r) => r.status == 200
    });
    sleep(1);
};
