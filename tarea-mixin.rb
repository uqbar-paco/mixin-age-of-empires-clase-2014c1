module M1
  def x
    30
  end
end

module M2
  def x
    20
  end
end

class A
  def x
    10
  end
end

class B < A
  include M1
  include M2

end


#main
b = B.new
puts b.x