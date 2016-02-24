struct Object {
  // members
  private path _path;
  private guide _guide;
  private Label _label;
  private pen _pen;
  private Object[] _children;

  // constructors
  void operator init() {
    this._path = nullpath;
    this._guide = nullpath;
    this._label = new Label;
    this._pen = defaultpen;
    this._children = new Object[];
  }
  void operator init(explicit path g, pen p = defaultpen,
                     Object[] children = new Object[]) {
    this._path = g;
    this._guide = nullpath;
    this._label = new Label;
    this._pen = p;
    this._children = children;
  }
  void operator init(explicit guide g, pen p = defaultpen,
                     Object[] children = new Object[]) {
    this._path = nullpath;
    this._guide = g;
    this._label = new Label;
    this._pen = p;
    this._children = children;
  }
  // void operator init(explicit object obj) {
  //   this._path = obj.getPath();
  //   this._guide = obj.getGuide();
  //   this._label = obj.getLabel();
  //   this._pen = obj.getPen();
  //   this._children = obj.getChildren();
  // }
  // predicates
  bool empty() { return (_path == nullpath) && (_guide == nullpath); }
  bool isPath() { return (_path != nullpath) && (_guide == nullpath); }
  bool isGuide() { return (_path == nullpath) && (_guide != nullpath); }
  bool hasChildren() { return this._children.length != 0; }
  // getters & setters
  path getPath() { return _path; }
  void setPath(explicit path g) { _path = g; _guide = nullpath; }
  guide getGuide() { return _guide; }
  void setGuide(explicit guide g) { _guide = g; _path = nullpath; }
  Label getLabel() { return _label; }
  void setLabel(Label label) { _label = label; }
  pen getPen() { return _pen; }
  void setPen(pen p) { _pen = p; }
  Object[] getChildren() { return _children; }
  void setChildren(explicit Object child) {
    _children.delete();
    _children.push(child);
  }
  void setChildren(explicit Object[] children) { _children = children; }
  // modifier
  void addChild(Object child) { this._children.push(child); }
  void removeChildren() { this._children.delete(); }

  // traversal
  // postorder == true  -> postorder
  // postorder == false -> preorder (default)
  typedef void visitorfn(Object obj);
  void traverse(visitorfn fn, bool postorder = false) {
    if (!postorder) {
      fn(this);
    }
    for (Object child : _children)
      child.traverse(fn);
    if (postorder) {
      fn(this);
    }
  }
  // helper struct for drawing
  private struct Painter {
    picture pic;
    void paint(Object obj) {
      label(pic, obj.getLabel(), obj.getPen());
      if (obj.empty())
        return;
      if (isPath())
        draw(pic, obj.getPath(), obj.getPen());
      if (isGuide())
        draw(pic, obj.getGuide(), obj.getPen());
    }
  }
  void draw(picture pic = currentpicture) {
    Painter painter;
    painter.pic = pic;
    visitorfn fn = painter.paint;
    traverse(fn);
  }
}

// cast
path operator ecast(Object obj) {
  assert(obj.isPath(), 'Not a path');
  return obj.getPath();
}

guide operator ecast(Object obj) {
  assert(obj.isGuide(), 'Not a guide');
  return obj.getGuide();
}

// transform
Object operator *(transform trans, Object obj) {
  Object[] cs = obj.getChildren();
  Object[] children = new Object[cs.length];
  for (int k = 0; k < cs.length; ++k)
    children[k] = trans * cs[k];
  Object ret = new Object;
  ret.setPath(trans*obj.getPath());
  ret.setLabel(trans*obj.getLabel());
  ret.setPen(obj.getPen());
  ret.setChildren(children);
  return ret;
}
