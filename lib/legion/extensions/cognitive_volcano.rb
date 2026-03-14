# frozen_string_literal: true

require 'securerandom'
require_relative 'cognitive_volcano/version'
require_relative 'cognitive_volcano/helpers/constants'
require_relative 'cognitive_volcano/helpers/magma'
require_relative 'cognitive_volcano/helpers/chamber'
require_relative 'cognitive_volcano/helpers/volcano_engine'
require_relative 'cognitive_volcano/runners/cognitive_volcano'
require_relative 'cognitive_volcano/client'

module Legion
  module Extensions
    module CognitiveVolcano
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
