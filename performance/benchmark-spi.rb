# frozen_string_literal: true

require 'benchmark'
require_relative 'theme_runner'

Liquid::Template.error_mode = ARGV.first.to_sym if ARGV.first
profiler = ThemeRunner.new

EBPF = false

if EBPF
  WARMUPS = 0
  N = 20
else
  WARMUPS = 1
  N = 200
end

puts "Do it #{N} times"
Benchmark.bm do |x|
  do_it = proc do
    N.times do
      profiler.compile
      profiler.render
      profiler.run
    end
  end

  WARMUPS.times do |i|
    x.report("warmup-#{i}") { do_it.call }
  end

  if defined?(GC::MMTk) && !GC::MMTk.enabled?
    stat1 = GC.stat
  end

  x.report("run") do
    GC::MMTk.harness_begin if defined?(GC::MMTk)# && GC::MMTk.enabled?
    do_it.call
    GC::MMTk.harness_end if defined?(GC::MMTk)# && GC::MMTk.enabled?
  end

  if defined?(GC::MMTk) && !GC::MMTk.enabled?
    stat2 = GC.stat

    num_gc = stat2[:count] - stat1[:count]
    gc_time = stat2[:time] - stat1[:time]

    puts "======== Begin GC.stat ========"
    puts "num_gc: #{num_gc}, gc_time: #{gc_time}"
    puts "======== End GC.stat ========"
  end
end
puts "Ended"
