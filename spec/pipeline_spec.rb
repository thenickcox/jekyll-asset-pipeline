require './spec/helper'

describe Pipeline do
  describe "class methods" do
    describe "::hash(source, manifest, options = {})" do
      let(:manifest) { "- /_assets/foo.css\n- /_assets/bar.css" }
      let(:hash) do
        Digest::MD5.hexdigest(YAML::load(manifest).map! do |path|
          "#{path}#{File.mtime(File.join(source_path, path)).to_i}"
        end.join.concat(JekyllAssetPipeline::DEFAULTS.to_s))
      end

      subject { JekyllAssetPipeline::Pipeline.hash(source_path, manifest) }

      it "should return a md5 hash of the manifest contents" do
        subject.must_equal(hash)
      end
    end # describe "::hash(source, manifest, options = {})"
  end # describe "class methods"

  describe "instance methods" do
    # Clean up temp files saved to spec/resources/temp
    after { FileUtils.remove_dir(temp_path, force: true) }

    let(:manifest) { "- /_assets/foo.css\n- /_assets/bar.css" }
    let(:prefix) { 'foobar' }
    let(:type) { '.css' }
    let(:options) { { } }
    let(:pipeline) { Pipeline.new(manifest, prefix, source_path, temp_path, type, options) }

    describe "#html" do
      subject { pipeline.html }

      before do
        # Mock custom converter
        template = MiniTest::Mock.new
        klass = MiniTest::Mock.new

        YAML::load(manifest).size.times do
          template.expect(:html, 'html')
          klass.expect(:filetype, '.css')
          klass.expect(:new, template, [String, String])
          klass.expect(:nil?, false)
        end

        JekyllAssetPipeline::Template.stub(:subclasses, [klass]) do
          pipeline.process
        end
      end

      context "with custom template" do
        it "outputs template html" do
          subject.must_equal('html')
        end
      end # context "with custom template"
    end # describe "#html"

    describe "#assets" do
      subject { pipeline.assets }

      context "with custom converter" do
        let(:manifest) { "- /_assets/foo.scss" }

        before do
          # Mock custom converter
          converter = MiniTest::Mock.new
          klass = MiniTest::Mock.new

          YAML::load(manifest).size.times do
            converter.expect(:converted, 'converted')
            2.times { klass.expect(:filetype, '.scss') }
            klass.expect(:new, converter, [JekyllAssetPipeline::Asset])
            klass.expect(:nil?, false)
          end

          JekyllAssetPipeline::Converter.stub(:subclasses, [klass]) do
            pipeline.process
          end
        end

        it "converts asset content" do
          subject.last.content.must_equal('converted')
        end
      end # context "with custom converter"

      context "bundle => true" do
        let(:options) { { 'bundle' => true } }

        before { pipeline.process }

        it "has one asset when multiple files are in manifest" do
          YAML::load(manifest).size.must_be :>, 1
          subject.size.must_equal(1)
        end

        it "generates a filename with md5 for the bundled asset" do
          hash = JekyllAssetPipeline::Pipeline.hash(source_path, manifest, options)
          subject.last.filename.must_equal("#{prefix}-#{hash}#{type}")
        end

        it "saves asset to disk at the output path" do
          File.exist?(File.join(temp_path, subject.last.output_path, subject.last.filename)).must_equal(true)
        end
      end #context "bundle => true"

      context "bundle => false" do
        let(:options) { { 'bundle' => false } }

        before { pipeline.process }

        it "has same number of assets as files in manifest" do
          subject.size.must_equal(YAML::load(manifest).size)
        end

        it "does not change the filenames of the assets" do
          YAML::load(manifest).each do |p|
            subject.select do |a|
              a.filename == File.basename(p)
            end.size.must_equal(1)
          end
        end

        it "saves assets to disk at the output path" do
          subject.each do |a|
            File.exist?(File.join(temp_path, a.output_path, a.filename)).must_equal(true)
          end
        end
      end #context "bundle => false"

      context "compress => true" do
        let(:options) { { 'compress' => true } }

        before do
          # Mock custom compressor
          compressor = MiniTest::Mock.new
          klass = MiniTest::Mock.new

          YAML::load(manifest).size.times do
            compressor.expect(:compressed, 'compressed')
            klass.expect(:filetype, '.css')
            klass.expect(:new, compressor, [String])
            klass.expect(:nil?, false)
          end

          JekyllAssetPipeline::Compressor.stub(:subclasses, [klass]) do
            pipeline.process
          end
        end

        it "compresses asset content" do
          subject.each { |a| a.content.must_equal('compressed') }
        end
      end # context "compress => true"

      context "gzip => true" do
        let(:options) { { 'gzip' => true } }
        let(:manifest) { "- /_assets/foo.css" }

        before do
          Zlib::Deflate.stub(:deflate, 'gzipped') do
            pipeline.process
          end
        end

        it "has twice as many assets as files in manifest" do
          subject.size.must_equal(YAML::load(manifest).size * 2)
        end

        it "creates half of assets with filenames ending in .gz" do
          subject.select do |asset|
            File.extname(asset.filename) == '.gz'
          end.size.must_equal(subject.size / 2)
        end

        it "gzips asset content" do
          subject.last.content.must_equal('gzipped')
        end
      end # context "gzip => true"

    end # describe "#process"
  end # describe "instance methods"
end # describe Pipeline
