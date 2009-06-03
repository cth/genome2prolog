#!/usr/bin/env ruby
# Point it to the directory where the genbank files are and it will generate
# Prolog representations of the files.

require 'rubygems'
require 'bio'

class String
  def to_prolog
    "'" + self.gsub("'",'\\\\\'') + "'"
  end
end

class Array
  def to_prolog
    to_prolog_list
  end
  
  def to_prolog_facts
    (self.map{ |e| e.to_prolog}).join('\n')
  end
  
  def to_prolog_list
    "[" + (self.map { |e| e.to_prolog}).join(',') + "]"
  end
end

class Range
  require 'equality.rb'
  include MusicBrainz::CoreExtensions::Range
end

# Change include? method of Range class to detect overlapping ranges
class Range
  alias :orig_include? :include?
  
  def include?(o)
    if o.class == Range
      o.min >= self.min and o.max <= self.max
    else
    	orig_include?(o)
    end
  end
end

# Class representing an entire genome
class Genome
  attr_accessor :id, :data

  def initialize(id, data)
    @id, @data = id, data
    @genes = []
    @gene_positions = []
  end
  
  def <<(gene)
    gene.genome = self
    gene.data = nil
    @genes << gene
  end
  
  def [](index)
    puts index.class
    puts index.inspect
    puts @data.class
    puts @data.length
    @data[index]
  end
  
  def inside_gene(position)
    @gene_positions.each do |pos|
      if position.class == Range
        position.each do |pos_elem|
          pos.include?(pos_elem)
        end
      end
      return true if pos.include(position)
    end    
  end
  
  # Infers non-gene regions when all gene regions have been added
  def nongenes
    
  end
  
  def to_prolog
    prolog ="genome('@id', #{@data.gsub("\n", "").downcase.split("").to_a.to_prolog}).\n"
    @genes.each do |gene|
      prolog << gene.to_prolog
    end
  end
end

class GenomeRange
  def initialize(start,stop,genome)
    @start, @stop, @genome = start, stop, genome
  end
  
  def data
    if @data.nil? and not @genome.nil?
      @genome[@start..@stop]
    else
      @data
    end
  end
  
  def position
    @start..@stop
  end
end

class Gene < GenomeRange
  attr_accessor :genome
  attr_writer :data
  
  def initialize(id, start, stop, data, genome=nil)
    @id, @start, @stop, @data, @genome = id, start, stop, data, genome
  end
  
  def to_prolog
    "gene('#{@id}', #{@start}, #{@stop}, #{data.gsub("\n","").downcase.split("").to_a.to_prolog_list})"
  end
end

class NonCoding < GenomeRange
end

class NCBIReader
  def initialize(dir)
    raise "No directory given!" if dir.nil?
    files = Dir.open(dir).to_a.map { |f| dir + "/" + f }
    files.each { |f| process_genome(Bio::FastaFormat.open(f)) if f =~ /.*\.fna/ }
    @genome ||= Genome.new(nil,nil) # Make a "null" genome if no genome file present
    files.each { |f| process_genes(Bio::FastaFormat.open(f)) if f =~ /.*\.ffn/ }
  end
  
  def process_genes(genes)
    genes.each { |gene| process_gene(gene) }
  end
  
  def process_gene(gene)
    defline = Bio::FastaDefline.new(gene.definition)
    if defline.list_ids[0][2] =~ /:(c?)(\d+)-(\d+)/
      @genome << Gene.new(defline.to_s,$2,$3,($1=="c" ? "complementary" : "primary"), gene.data)
    end
  end
  
  def process_genome(genome)
    genome.each do |g| # Even though we only expect one genome, have to do it like this...
      defline = Bio::FastaDefline.new(g.definition) 
      @genome = Genome.new(defline.list_ids[0][1], g.data)
    end
  end
  
  def count_frequencies(lower_chunk_size_limit, upper_chunk_size_limit, sequence, collector)
    count_table={}
    lower_chunk_size.upto(upper_chunk_size_limit) do |i|
      position = 0
      dna.window_search(i,1) do |chunk|
        position = position + 1
        collector.add_count(position, chunk)
      end
    end
  end
  
  def write_prolog_file(filename)
    File.open(filename, "w") { |f| f << @genome.to_prolog }
  end
end

datadir = ARGV.shift
outputfile = ARGV.shift
g = NCBIReader.new(datadir)
g.write_prolog_file(outputfile)


