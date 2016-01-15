import geometry;                // for mass calculation
import object;

struct MatrixShape {
  static int GENERAL = 0;
  static int SQUARE = 1;
  static int TRIANGULAR = 2;
  static int TRAPEZOIDAL = 3;
  static int BAND = 4;
  static int count() { return BAND+1; }
  private static string[] _names = new string[] {
    'General', 'Square', 'Triangular', 'Trapezoidal', 'Band'
  };
  static bool validate(int shape) { return GENERAL <= shape && shape < count(); }
  static string getShapeName(int shape) {
    assert(validate(shape), 'Invalid shape');
    return _names[shape];
  }
}
unravel MatrixShape;

struct MatrixUplo {
  static int UP = 0;
  static int LO = 1;
  static string[] UploName = new string[] {'up', 'lo'};
}
unravel MatrixUplo;

struct Matrix {
  // members
  private int _shape;
  private int _uplo;
  private int _kl;
  private int _ku;
  private int _row;
  private int _col;
  private pair _base;
  private Matrix[] _submatrices; // row major
  private Label _label;
  private pen _pen;


  // predicates
  bool isGeneral() { return _shape == GENERAL; }
  bool isSquare() { return _shape == SQUARE; }
  bool isTriangular() { return _shape == TRIANGULAR; }
  bool isTrapezoidal() { return _shape == TRAPEZOIDAL; }
  bool isBand() { return _shape == BAND; }
  bool isUp() { return _uplo == UP; }
  bool isLo() { return _uplo == LO; }
  
  // getters & setters
  int getShape() { return _shape; }
  int getUplo() { return _uplo; }
  int getSubWidth() { return _kl; }
  int getSuperWidth() { return _ku; }
  int getRow() { return _row; }
  int getCol() { return _col; }
  pen getPen() { return _pen; }
  pair getBase() { return _base; }
  Matrix[] getSubMatrices() { return _submatrices; }
  Matrix getSubMatrix(int i) {
    assert(i < _submatrices.length, 'Out of bound');
    return _submatrices[i];
  }
  Label getLabel() { return _label; }
  // we only provide setter for _pen
  void setPen(pen p) { _pen = p; }
  void setLabel(explicit Label l) { _label = l; }
  void resetLabel() { _label = new Label; }

  // static creator functions, use these instead of constructors
  static Matrix general(explicit int row, explicit int col,
                        explicit pair base = (0, 0), explicit pen p = currentpen) {
    assert(row > 0 && col > 0, 'Invalid matrix dimension');
    Matrix m = new Matrix;
    m._shape = GENERAL;
    m._uplo = -1;
    m._kl = -1;
    m._ku = -1;
    m._row = row;
    m._col = col;
    m._base = base;
    m._submatrices = new Matrix[];
    m._label = new Label;
    m._pen = p;
    return m;
  }
  static Matrix square(explicit int dim, explicit pair base = (0, 0),
                       explicit pen p = currentpen) {
    assert(dim > 0, 'Invalid matrix dimension');
    Matrix m = new Matrix;
    m._shape = SQUARE;
    m._uplo = -1;
    m._kl = -1;
    m._ku = -1;
    m._row = dim;
    m._col = dim;
    m._base = base;
    m._submatrices = new Matrix[];
    m._label = new Label;
    m._pen = p;
    return m;
  }
  static Matrix triangular(explicit int dim, explicit int uplo,
                           explicit pair base = (0, 0), explicit pen p = currentpen) {
    assert(dim > 0, 'Invalid matrix dimension');
    assert(uplo == UP || uplo == LO, 'Invalid matrix uplo');
    Matrix m = new Matrix;
    m._shape = TRIANGULAR;
    m._uplo = uplo;
    m._kl = -1;
    m._ku = -1;
    m._row = dim;
    m._col = dim;
    m._base = base;
    m._submatrices = new Matrix[];
    m._pen = p;
    return m;
  }
  static Matrix trapezoidal(explicit int row, explicit int col,
                            explicit int uplo, explicit pair base = (0, 0),
                            explicit pen p = currentpen) {
    assert(row > 0 && col > 0, 'Invalid matrix dimension');
    assert(uplo == UP || uplo == LO, 'Invalid matrix uplo');
    Matrix m = new Matrix;
    m._shape = TRAPEZOIDAL;
    m._uplo = uplo;
    m._kl = -1;
    m._ku = -1;
    m._row = row;
    m._col = col;
    m._base = base;
    m._submatrices = new Matrix[];
    m._label = new Label;
    m._pen = p;
    return m;
  }
  static Matrix band(explicit int row, explicit int col,
                     explicit int uplo, explicit int kl,
                     explicit int ku, explicit pair base = (0, 0),
                     explicit pen p = currentpen) {
    assert(row > 0 && col > 0, 'Invalid matrix dimension');
    assert(uplo == UP || uplo == LO, 'Invalid matrix uplo');
    assert(ku >= 0 && kl >= 0, 'Invalid band width');
    Matrix m = new Matrix;
    m._shape = BAND;
    m._uplo = uplo;
    m._kl = kl;
    m._ku = ku;
    m._row = row;
    m._col = col;
    m._base = base;
    m._submatrices = new Matrix[];
    m._label = new Label;
    m._pen = p;
    return m;
  }

  // conversion
  void convert(int shape) {
    assert(MatrixShape.validate(shape), 'Invalid shape');
    if (isGeneral()) {
      if (shape == SQUARE) {
        assert(_row == _col, 'Invalid conversion');
        _shape == SQUARE;
      } else
        assert(false, 'Not support yet');
    } else {
      assert(false, 'Not support yet');
    }
  }

  // tile
  void detile() { _submatrices.delete(); }
  // we only support tiling in single dimension
  private void tileRowGeneral(explicit int[] sizes) {
    assert(sizes.length > 0, 'Empty tile sizes');
    assert(all(sizes > 0), 'Non-positive tile size');
    assert(sum(sizes) == _row, 'Tile sizes mismatch');
    _submatrices = new Matrix[sizes.length];
    real rbase = _base.y, cbase = _base.x;
    for (int i = 0; i < sizes.length; ++i) {
      int size = sizes[i];
      Matrix m = Matrix.general(size, _col, (cbase, rbase), _pen);
      _submatrices[i] = m;
      rbase -= size;
    }
  }
  private void tileColGeneral(explicit int[] sizes) {
    assert(sizes.length > 0, 'Empty tile sizes');
    assert(all(sizes > 0), 'Non-positive tile size');
    assert(sum(sizes) == _col, 'Tile sizes mismatch');
    _submatrices = new Matrix[sizes.length];
    real rbase = _base.y, cbase = _base.x;
    for (int i = 0; i < sizes.length; ++i) {
      int size = sizes[i];
      Matrix m = Matrix.general(_row, size, (cbase, rbase), _pen);
      _submatrices[i] = m;
      cbase += size;
    }
  }
  private void tileRowGeneral(explicit int size) {
    assert(size > 0, 'Non-positive tile size');
    int n = quotient(_row, size);
    n += _row % size == 0? 0 : 1;
    _submatrices = new Matrix[n];
    real rbase = _base.y, cbase = _base.x;
    int i = 0;
    for (int r = 0; r < _row; r += size) {
      Matrix m = Matrix.general(min(size, _row-r), _col, (cbase, rbase-r), _pen);
      _submatrices[i] = m;
      ++i;
    }
  }
  private void tileColGeneral(explicit int size) {
    assert(size > 0, 'Non-positive tile size');
    int n = quotient(_col, size);
    n += _col % size == 0? 0 : 1;
    _submatrices = new Matrix[n];
    real rbase = _base.y, cbase = _base.x;
    int i = 0;
    for (int c = 0; c < _col; c += size) {
      Matrix m = Matrix.general(_row, min(size, _col-c), (cbase+c, rbase), _pen);
      _submatrices[i] = m;
      ++i;
    }
  }
  private void tileRowSquare(explicit int[] sizes) { tileRowGeneral(sizes); }
  private void tileColSquare(explicit int[] sizes) { tileColGeneral(sizes); }
  private void tileRowSquare(explicit int size) { tileRowGeneral(size); }
  private void tileColSquare(explicit int size) { tileColGeneral(size); }

  void tileRow(explicit int[] sizes) {
    assert(!isBand(), 'Row tiling of band matrix is not supported');
    if (isGeneral())
      tileRowGeneral(sizes);
    else if (isSquare())
      tileRowSquare(sizes);
    else
      assert(false, 'Not supported yet');
  }
  void tileCol(explicit int[] sizes) {
    assert(!isBand(), 'Col tiling of band matrix is not supported');
    if (isGeneral())
      tileColGeneral(sizes);
    else if (isSquare())
      tileColSquare(sizes);
    else
      assert(false, 'Not supported yet');
  }
  void tileRow(explicit int size) {
    assert(!isBand(), 'Row tiling of band matrix is not supported');
    if (isGeneral())
      tileRowGeneral(size);
    else if (isSquare())
      tileRowSquare(size);
    else
      assert(false, 'Not supported yet');
  }
  void tileCol(explicit int size) {
    assert(!isBand(), 'Col tiling of band matrix is not supported');
    if (isGeneral())
      tileColGeneral(size);
    else if (isSquare())
      tileColSquare(size);
    else
      assert(false, 'Not supported yet');
  }

  private void tileDiagonalSquare() {
    _submatrices = new Matrix[2];
    _submatrices[0] = Matrix.triangular(_row, LO, _base, _pen);
    _submatrices[1] = Matrix.triangular(_row, UP, _base, _pen);
  }
  private void tileDiagonalGeneral() {
    if (_row == _col) {
      convert(SQUARE);
      tileDiagonalSquare();
      return;
    } else if (_row < _col) {
      _submatrices = new Matrix[2];
      _submatrices[0] = Matrix.triangular(_row, LO, _base, _pen);
      _submatrices[1] = Matrix.trapezoidal(_row, _col, UP, _base, _pen);
    } else {
      _submatrices = new Matrix[2];
      _submatrices[0] = Matrix.trapezoidal(_row, _col, LO, _base, _pen);
      _submatrices[1] = Matrix.triangular(_col, UP, _base, _pen);
    }
  }
  void tileDiagonal() {
    assert(isGeneral() || isSquare(), 'Not supported yet');
    if (isGeneral())
      tileDiagonalGeneral();
    else if (isSquare())
      tileDiagonalSquare();
    else
      assert(false, 'Invalid shape');
  }
  
  // print
  string toString(bool recursive = true, string indent = '') {
    string ret = indent + MatrixShape.getShapeName(_shape) +
      format('Matrix[%d]', _row) + format('[%d]: ', _col) + (string)_base;
    if (recursive) {
      ret += ' {\n';
      for (int i = 0; i < _submatrices.length; ++i)
        ret += _submatrices[i].toString(recursive, indent+'  ') + '\n';
      ret += indent + '}';
    }
    return ret;
  }
  // draw
  private guide toGuideGeneral() {
    return shift(_base)*scale(_col, _row)*rotate(-90)*unitsquare;
  }
  private guide toGuideSquare() = toGuideGeneral;
  private guide toGuideTriangular() {
    guide g;
    if (isUp())
      g = (0, 0)--(1, 0)--(1, -1)--cycle;
    else
      g = (0, 0)--(0, -1)--(1, -1)--cycle;
    return shift(_base)*scale(_row)*g;
  }
  private guide toGuideTrapezoidal() {
    path g;
    if (isUp())
      g = (0, 0)--(_col, 0)--(_col, _row)--(_col-_row, -_row)--cycle;
    else
      g = (0, 0)--(0, -_row)--(_col, -_row)--(_col, -_col)--cycle;
    return shift(_base)*g;
  }
  private guide toGuide() {
    if (isGeneral())
      return toGuideGeneral();
    else if (isSquare())
      return toGuideSquare();
    else if (isTriangular())
      return toGuideTriangular();
    else if (isTrapezoidal()) {
      return toGuideTrapezoidal();
    }
    else {
      write(_shape);
      assert(false, 'Not supported yet');
      return nullpath;
    }
  }
  pair masscenter() {
    // static pair[] pointcollector(guide) = new pair[] (path p) {
    //   pair[] points = new pair[size(p)];
    //   for (int i = 0; i < size(p); ++i)
    //     points[i] = point(p, i);
    //   return points;
    // }
    guide g = toGuide();
    mass mc = point(g, 0);
    for (int i = 1; i < size(g); ++i)
      mc = masscenter(mc, point(g, i));
    return (point)mc;
  }
  private Object render() {
    guide g = toGuide();
    Object[] children = new Object[];
    for (int i = 0; i < _submatrices.length; ++i)
      children.push(_submatrices[i].render());
    Object obj = Object(g, _pen, children);
    obj.setLabel(_label);
    return obj;
  }
  void draw(picture pic = currentpicture) {
    Object obj = render();
    obj.draw(pic);
  }

  // must be defined after masscenter
  void setLabel(string l) { setLabel(Label(l, this.masscenter())); }
}

string operator cast(Matrix m) { return m.toString(); }

