require 'fileutils'
require 'shellwords'

module SCM
  module Util
    protected

    #
    # Runs a program.
    #
    # @param [String, Symbol] program
    #   The name or path of the program.
    #
    # @param [Array] arguments
    #   Optional arguments for the program.
    #
    # @return [Boolean]
    #   Specifies whether the program exited successfully.
    #
    def run(program,*arguments)
      arguments = arguments.map(&:to_s)

      # filter out empty Strings
      arguments.reject!(&:empty?)

      system(program.to_s,*arguments)
    end

    #
    # Runs a command as a separate process.
    #
    # @param [String] command
    #   The command to run.
    #
    # @param [Array] arguments
    #   Additional arguments for the command.
    #
    # @yield [line]
    #   The given block will be passed each line read-in.
    #
    # @yieldparam [String] line
    #   A line read from the program.
    #
    # @return [IO]
    #   The stdout of the command being ran.
    #
    def popen(command,*arguments)
      unless arguments.empty?
        command = command.dup

        arguments.each do |arg|
          command << ' ' << Shellwords.shellescape(arg.to_s)
        end
      end

      io = IO.popen(command)

      if block_given?
        io.each_line do |line|
          line.chomp!
          yield line
        end
      end

      return io
    end

    #
    # Read lines until a separator line is encountered.
    #
    # @param [IO] io
    #   The IO stream to read from.
    #
    # @param [String] separator
    #   The separator line to stop at.
    #
    # @return [Array<String>]
    #   The read lines.
    #
    def readlines_until(io,separator='')
      lines = []

      until io.eof?
        line = io.readline
        line.chomp!

        break if line == separator

        lines << line
      end

      return lines
    end
  end
end
