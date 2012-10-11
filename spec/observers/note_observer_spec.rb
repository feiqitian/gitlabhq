require 'spec_helper'

describe NoteObserver do
  subject { NoteObserver.instance }

  describe '#after_create' do
    let(:note) { double :note, notify: false, notify_author: false }

    it 'is called after a note is created' do
      subject.should_receive :after_create

      Note.observers.enable :note_observer do
        Factory.create(:note)
      end
    end

    it 'notifies team of new note when flagged to notify' do
      note.stub(:notify).and_return(true)
      subject.should_receive(:notify_team_of_new_note).with(note)

      subject.after_create(note)
    end
    it 'does not notify team of new note when not flagged to notify' do
      subject.should_not_receive(:notify_team_of_new_note).with(note)

      subject.after_create(note)
    end
    it 'notifies the author of a commit when flagged to notify the author' do
      note.stub(:notify_author).and_return(true)
      note.stub(:id).and_return(42)
      author = double :user, id: 1
      note.stub(:commit_author).and_return(author)
      Notify.should_receive(:note_commit_email).and_return(double(deliver: true))

      subject.after_create(note)
    end
    it 'does not notify the author of a commit when not flagged to notify the author' do
      Notify.should_not_receive(:note_commit_email)

      subject.after_create(note)
    end
    it 'does nothing if no notify flags are set' do
      subject.after_create(note).should be_nil
    end
  end


  let(:team_without_author) { (1..2).map { |n| double :user, id: n } }

  describe '#notify_team_of_new_note' do
    let(:note) { double :note, id: 1 }

    before :each do
      subject.stub(:team_without_note_author).with(note).and_return(team_without_author)
    end

    context 'notifies team of a new note on' do
      it 'a commit' do
        note.stub(:noteable_type).and_return('Commit')
        Notify.should_receive(:note_commit_email).twice.and_return(double(deliver: true))

        subject.send(:notify_team_of_new_note, note)
      end
      it 'an issue' do
        note.stub(:noteable_type).and_return('Issue')
        Notify.should_receive(:note_issue_email).twice.and_return(double(deliver: true))

        subject.send(:notify_team_of_new_note, note)
      end
      it 'a wiki page' do
        note.stub(:noteable_type).and_return('Wiki')
        Notify.should_receive(:note_wiki_email).twice.and_return(double(deliver: true))

        subject.send(:notify_team_of_new_note, note)
      end
      it 'a merge request' do
        note.stub(:noteable_type).and_return('MergeRequest')
        Notify.should_receive(:note_merge_request_email).twice.and_return(double(deliver: true))

        subject.send(:notify_team_of_new_note, note)
      end
      it 'a wall' do
        note.stub(:noteable_type).and_return('Wall')
        Notify.should_receive(:note_wall_email).twice.and_return(double(deliver: true))

        subject.send(:notify_team_of_new_note, note)
      end
    end

    it 'does nothing for a new note on a snippet' do
        note.stub(:noteable_type).and_return('Snippet')

        subject.send(:notify_team_of_new_note, note).should == [true, true]
    end
  end


  describe '#team_without_note_author' do
    let(:author) { double :user, id: 4 }

    let(:users) { team_without_author + [author] }
    let(:project)  { double :project, users: users }
    let(:note) { double :note, project: project, author: author }

    it 'returns the projects user without the note author included' do
      subject.send(:team_without_note_author, note).should == team_without_author
    end
  end
end