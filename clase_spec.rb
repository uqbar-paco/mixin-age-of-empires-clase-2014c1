require 'rspec'
module Descansador
  def descansar
    self.energia += 10
  end
end

#mixin Defensor
module Defensor
  attr_accessor :energia, :potencial_defensivo
  attr_accessor :interesados

  def reducir_energia(energia_a_reducir)
    self.energia = self.energia - energia_a_reducir
    self.avisar_interesados
  end

  def add_interesado(interesado)
    self.interesados << interesado
  end

  def interesados
    @interesados = @interesados || []
    @interesados
  end

  def avisar_interesados
    self.interesados.each do |interesado|
      interesado.call(self)
    end
  end
end


#mixin Atacante
module Atacante
  def ataca_a(defensor)
    if self.puede_atacar_a defensor
      defensor.reducir_energia (self.potencial_ofensivo_efectivo -
          defensor.potencial_defensivo)
    end
  end

  def puede_atacar_a(guerrero)
    self.potencial_ofensivo_efectivo > guerrero.potencial_defensivo
  end

  def potencial_ofensivo_efectivo
    self.potencial_ofensivo
  end

  def potencial_ofensivo
    raise 'mixin_self_requirement'
  end
end

module DobleAtaque
  include Atacante

  attr_accessor :esta_descansado

  def descansar
    self.esta_descansado = true
  end

  def ataca_a(defensor)
    super
    self.esta_descansado = false
  end

  def potencial_ofensivo_efectivo
    super * (self.esta_descansado ? 2 : 1)
  end
end

class Muralla

  include Descansador
  include Defensor

  def initialize
    self.energia = 200
    self.potencial_defensivo= 20
  end

end

class Misil
  include DobleAtaque

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

  include DobleAtaque
  alias :descansar_atacar :descansar

  include Descansador
  alias :descansar_defensor :descansar

  attr_accessor :potencial_ofensivo

  def initialize
    self.energia = 100
    self.potencial_ofensivo= 30
    self.potencial_defensivo= 20
  end

  def descansar
    self.descansar_defensor
    self.descansar_atacar
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

class Ejercito
  attr_accessor :unidades, :estrategia_defensiva
  attr_accessor :se_retira

  def self.new_ejercito_cagon
    ejercito = Ejercito.new
    ejercito.estrategia_defensiva = lambda {
        |unidad, ejercito|
      ejercito.se_retira = true
    }
    ejercito
  end

  def self.new_ejercito_protector
    ejercito = Ejercito.new
    ejercito.estrategia_defensiva = proc {
      |unidad, ejercito|
      unidad.descansar
    }
    ejercito
  end

  def initialize
    self.unidades = []
    self.se_retira = false
  end

  def me_lastimaron(unidad)
    estrategia_defensiva.call unidad, self
  end

  def add_unidad(unidad)
    self.unidades << unidad
    unidad.add_interesado(lambda {|unidad|
      self.me_lastimaron(unidad)
    })
  end
end


class Mago
  def curar(unidad)

  end
  def teletransportar(unidad)

  end
end
describe 'Age of empires' do

  it 'un defensor avisa al ejercito cuando es lastimado' do
    ejercito = Ejercito.new_ejercito_protector

    atila = Guerrero.new
    conan = Guerrero.new

    ejercito.add_unidad atila

    conan.ataca_a atila

    atila.esta_descansado.should == true

  end

  it 'quiero que un mago pueda curar tambien a una unidad' do

    atila = Guerrero.new
    conan = Guerrero.new
    mago = Mago.new

    atila.add_interesado(lambda {|unidad|
      mago.curar(unidad)
    }) # Curar

    conan.add_interesado(lambda {|unidad|
      mago.teletransportar(unidad)
    }) # Teletransportar

    conan.ataca_a atila

  end

  it 'el ejercito cagon se retira cuando lo atacan' do
    ejercito = Ejercito.new_ejercito_cagon

    ejercito.se_retira.should == false
    atila = Guerrero.new
    conan = Guerrero.new

    ejercito.add_unidad atila

    conan.ataca_a atila

    ejercito.se_retira.should == true

  end

  it 'cuando la muralla descansa recupera energia' do
    muralla = Muralla.new
    energia_original = muralla.energia

    muralla.descansar

    muralla.energia.should == energia_original + 10
  end

  it 'misil ataca a atila descansado' do
    #Un defensor empezo con 100 de energia
    misil = Misil.new
    atila = Guerrero.new
    #
    misil.descansar

    misil.ataca_a atila

    atila.energia.should == -80

    misil.ataca_a atila

    # Perdio 80 y no 180
    atila.energia.should == -160
  end

  #Esto es un test
  it 'conan ataca a atila' do
    #Un defensor empezo con 100 de energia
    atila = Guerrero.new
    conan = Guerrero.new
    #
    conan.ataca_a atila

    atila.energia.should == 90
  end

  it 'un guerrero ataca a otro descansado y hace las 2 cosas' do
    #Un defensor empezo con 100 de energia
    atila = Guerrero.new
    conan = Guerrero.new
    energia_original = conan.energia

    conan.descansar
    conan.ataca_a atila

    conan.energia.should == energia_original + 10
    atila.energia.should == 60
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