{
  callTransform = path: a: b:
    let thing = import path (a // { self = thing; }) b; in thing;
}
