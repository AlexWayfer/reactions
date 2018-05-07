# frozen_string_literal: true

require 'gorilla-patch/deep_dup'
require_relative 'coercion'

module Formalism
	## Class for forms
	class Form < Action
		class << self
			def fields
				@fields ||= {}
			end

			def nested_forms
				@nested_forms ||= {}
			end

			private

			def field(name, type = nil, **options)
				Coercion.check type unless type.nil?
				fields[name] = options.merge(type: type)
				attr_accessor name
			end

			def nested(name, form)
				nested_forms[name] = form
				define_method("#{name}_form") { nested_forms[name] }
				define_method(name) { nested_forms[name].public_send(name) }
			end

			def inherited(child)
				child.fields.merge!(fields)
			end
		end

		attr_reader :params

		using GorillaPatch::DeepDup

		def initialize(params = {})
			@params = params.deep_dup
			self.class.fields.each do |name, _options|
				public_send "#{name}=", params[name]
			end
			self.class.nested_forms.each do |name, form|
				nested_forms[name] = form.new(params[name])
			end
		end

		def fields
			@fields ||=
				self.class.fields.each_with_object({}) do |(name, options), hash|
					next unless @params.key?(name) || options.key?(:default)
					hash[name] =
						if @params.key?(name)
						then Coercion.new(public_send(name), options[:type]).result
						else options[:default]
						end
				end
		end

		def valid?
			errors.clear
			nested_forms.each_value(&:valid?)
			validate
			errors.merge(nested_forms.each_value.map(&:errors)).flatten!
			return false if errors.any?
			true
		end

		def errors
			@errors ||= Set.new
		end

		def run
			return false unless valid?
			nested_forms.each_value(&:run)
			super
			true
		end

		private

		def nested_forms
			@nested_forms ||= {}
		end
	end
end
