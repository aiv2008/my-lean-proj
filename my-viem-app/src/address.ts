export function shortAddress(address: string) {
  return `${address.slice(0, 6)}…${address.slice(-4)}`
}

export function isSameAddress(a?: string|null, b?: string|null){
    return !!a && !!b && a.toLowerCase() === b.toLowerCase();
}
