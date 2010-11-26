require 'helper'

class TestCheckm < Test::Unit::TestCase
  def test_empty
    checkm = ''
    res = Checkm::Manifest.parse(checkm)
    assert_equal(res.entries.empty?, true)
  end

  def test_comment
    checkm = '#'
    res = Checkm::Manifest.parse(checkm)
    assert_equal(res.entries.empty?, true)
  end

  def test_version
    checkm = '#%checkm_0.7'
    res = Checkm::Manifest.parse(checkm)
    assert_equal(res.entries.empty?, true)
    assert_equal(res.version, '0.7')
  end

  def test_parse_simple
    checkm = 'book/Chapter9.xml |   md5   |  49afbd86a1ca9f34b677a3f09655eae9'
    res = Checkm::Manifest.parse(checkm)
    assert_equal(res.entries.length, 1)
    assert_equal(res.entries.first.values[0], 'book/Chapter9.xml')
    assert_equal(res.entries.first.values[1], 'md5')
    assert_equal(res.entries.first.values[2], '49afbd86a1ca9f34b677a3f09655eae9')
  end

  def test_parse_named_fields
    checkm = 'book/Chapter9.xml |   md5   |  49afbd86a1ca9f34b677a3f09655eae9'
    res = Checkm::Manifest.parse(checkm)
    assert_equal(res.entries.length, 1)
    assert_equal(res.entries.first.sourcefileorurl, 'book/Chapter9.xml')
    assert_equal(res.entries.first.alg, 'md5')
    assert_equal(res.entries.first.digest, '49afbd86a1ca9f34b677a3f09655eae9')
  end

  def test_parse_custom_fields
    checkm= '#%fields | testa | test b' + "\n" +
            'book/Chapter9.xml |   md5   |  49afbd86a1ca9f34b677a3f09655eae9'

	    
    res = Checkm::Manifest.parse(checkm)
    assert_equal(res.entries.length, 1)
    assert_equal(res.entries.first.sourcefileorurl, 'book/Chapter9.xml')
    assert_equal(res.entries.first.testa, 'book/Chapter9.xml')
    assert_equal(res.entries.first.alg, 'md5')
    assert_equal(res.entries.first.send(:'test b'), 'md5')
    assert_equal(res.entries.first.digest, '49afbd86a1ca9f34b677a3f09655eae9')
  end

  def test_valid
    checkm = '1 | md5 | b026324c6904b2a9cb4b88d6d61c81d1'
    res = Checkm::Manifest.parse(checkm, :path => File.join(File.dirname(__FILE__), 'test_1'))
    assert_equal(res.entries.length, 1)
    assert_equal(res.entries.first.valid?, true)
  end

  def test_valid_dir
    checkm = 'test_1 | dir'
    res = Checkm::Manifest.parse(checkm, :path => File.join(File.dirname(__FILE__)))

    assert_equal(res.entries.length, 1)
    assert_equal(res.entries.first.valid?, true)
  end

  def test_invalid_missing_file
    checkm = '2 | md5 | b026324c6904b2a9cb4b88d6d61c81d1'
    res = Checkm::Manifest.parse(checkm, :path => File.join(File.dirname(__FILE__), 'test_1'))
    assert_equal(res.entries.length, 1)
    assert_equal(res.entries.first.valid?, false)
  end

  def test_invalid_bad_checksum
    checkm = '1 | md5 | zzz'
    res = Checkm::Manifest.parse(checkm, :path => File.join(File.dirname(__FILE__), 'test_1'))
    assert_equal(res.entries.length, 1)
    assert_equal(res.entries.first.valid?, false)
  end

  def test_create_entry
    res = Checkm::Entry.create('LICENSE.txt')
    assert_match( /LICENSE\.txt | md5 | 927368f89ca84dbec878a8d017f06443 | 1054 | \d{4}/, res)
  end

  def test_manifest_add
    m = Checkm::Manifest.parse('')
    n = m.add('LICENSE.txt')
    assert_equal(n.entries.length, 1)
    assert_equal(n.entries.first.valid?, true)
  end

  def test_manifest_add
    m = Checkm::Manifest.parse('')
    n = m.add('LICENSE.txt')
    assert_equal(n.entries.length, 1)
    assert_equal(n.entries.first.valid?, true)
  end

  def test_manifest_to_s
    m = Checkm::Manifest.parse('')
    n = m.add('LICENSE.txt')
    lines = n.to_s.split "\n"
    assert_equal(lines[0], '#%checkm_0.7')
    assert_match(/^LICENSE\.txt/, lines[1])
  end
end
