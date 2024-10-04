const log_enc = new TextEncoder();

self.onmessage = async (e) => {
  if (e.data === null) {
    self.close();
    return;
  }

  const data = log_enc.encode(e.data.join("\n") + "\n");
  Deno.stdout.writeSync(data);
};
