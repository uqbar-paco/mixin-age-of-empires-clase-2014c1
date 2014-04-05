require 'rspec'

#mixin Defensor
module Defensor
  attr_accessor :energia, :potencial_defensivo

  def reducir_energia(energia_a_reducir)
    self.energia= self.energia - energia_a_reducir
  end
end

#mixin Atacante
module Atacante

  def ataca_a(defensor)
    if self.puede_atacar_a defensor
      defensor.reducir_energia (self.potencial_ofensivo -
          defensor.potencial_defensivo)
    end
  end

  def potencial_ofensivo
    raise 'mixin_self_requirement'
  end

  def puede_atacar_a(guerrero)
    self.potencial_ofensivo > guerrero.potencial_defensivo
  end

end

class Muralla
  include Defensor

  def initialize
    self.energia = 200
    self.potencial_defensivo= 20
  end

end

class Misil
  include Atacante

  def potencial_ofensivo
    100
  end

end

#Defensor
#   ^
#   |
#Atacante
#   ^
#   |
#Guerrero
class Guerrero
  include Defensor
  include Atacante

  attr_accessor :potencial_ofensivo

  def initialize
    self.energia = 100
    self.potencial_ofensivo= 30
    self.potencial_defensivo= 20
  end

end

class Espadachin < Guerrero
  attr_accessor :habilidad, :potencial_ofensivo_espada

  def initialize
    super
    self.habilidad = 1
    self.potencial_ofensivo_espada= 20
  end

  def potencial_ofensivo
    super + self.potencial_ofensivo_espada * self.habilidad
  end

end

describe 'Age of empires' do

  #Esto es un test
  it 'conan ataca a atila' do
    #Un defensor empezo con 100 de energia
    atila = Guerrero.new
    conan = Guerrero.new
    #
    conan.ataca_a atila

    atila.energia.should == 90
  end

  it 'espadachin ataca a atila' do
    zorro = Espadachin.new
    atila = Guerrero.new

    zorro.ataca_a atila

    atila.energia.should == 70

  end

  it 'atila ataca a muralla' do
    atila = Guerrero.new
    muralla = Muralla.new

    atila.ataca_a muralla
    muralla.energia.should == 190

  end

  it 'Muralla no deberia atacar a atila' do
    muralla = Muralla.new
    atila = Guerrero.new

    expect {
      muralla.ataca_a atila
    }.to raise_error NoMethodError #DoesNotUnderstand ataca_a

  end

  it 'misil ataca a muralla' do
    misil = Misil.new
    muralla = Muralla.new

    misil.ataca_a muralla
    muralla.energia.should == 120
  end

  it 'misil no se puede defender' do
    misil = Misil.new
    atila = Guerrero.new
    expect {
      atila.ataca_a misil
    }.to raise_error NoMethodError
  end

end