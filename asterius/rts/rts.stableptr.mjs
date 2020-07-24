export class StablePtrManager {
  constructor() {
    this.spt = new Map();
    this.lasts = [0n, 0n];
    Object.freeze(this);
  }

  newWithTag(v, tag) {
    const sp = (++this.lasts[tag] << 1n) | tag;
    this.spt.set(sp, v);
    return sp;
  }

  newStablePtr(addr) {
    return this.newWithTag(addr, 0n);
  }

  deRefStablePtr(sp) {
    return this.spt.get(sp);
  }

  freeStablePtr(sp) {
    this.spt.delete(sp);
  }

  newJSVal(v) {
    return this.newWithTag(v, 1n);
  }

  getJSVal(sp) {
    return this.deRefStablePtr(sp);
  }

  freeJSVal(sp) {
    this.freeStablePtr(sp);
  }

  hasStablePtr(sp) {
    return this.spt.has(sp);
  }

  preserveJSVals(sps) {
    for (const sp of Array.from(this.spt.keys()))
      if (sp & 1 && !sps.has(sp)) this.freeJSVal(sp);
  }
}
