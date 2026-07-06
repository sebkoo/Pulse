import { createApp } from "./app";
import { liveGateway } from "./upstream";

const port = Number(process.env.PORT ?? 8081);

createApp(liveGateway).listen(port, () => {
  console.log(`pulse-bff listening on http://127.0.0.1:${port}`);
});
