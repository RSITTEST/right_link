#
# Copyright (c) 2009 RightScale Inc
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Code taken from RAILS which allows checking whether '.dup' can be called
# on an arbitrary object
class Object
  # Can you safely .dup this object?
  # False for nil, false, true, symbols, numbers, and class objects; true otherwise.
  def duplicable?
    true
  end
end

class NilClass #:nodoc:
  def duplicable?
    false
  end
end

class FalseClass #:nodoc:
  def duplicable?
    false
  end
end

class TrueClass #:nodoc:
  def duplicable?
    false
  end
end

class Symbol #:nodoc:
  def duplicable?
    false
  end
end

class Numeric #:nodoc:
  def duplicable?
    false
  end
end

class Class #:nodoc:
  def duplicable?
    false
  end
end