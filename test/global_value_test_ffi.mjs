const messages = [];

export function rec() {
  if (messages.length === 0) {
    throw "no more messages";
  }
  return messages.shift();
}

export function send(m) {
  messages.push(m);
}

export function yield_(ms, f) {
  setTimeout(f, ms);
}

export function spawn(f) {
  setTimeout(f, 1);
}

export function self() {}

export function unique_int() {
  return Math.floor(Math.random() * 1000000);
}

export function sleep(ms) {
  const end = Date.now() + ms;
  while (Date.now() < end) {
    // Busy-wait loop, blocks the event loop
  }
}
