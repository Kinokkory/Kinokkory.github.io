		�֐��I�X�g���[���� tail �������@

�܂�A�֐��I�����^���s�p���X�g���[���̍ŏ��̐��v�f���A�ŏ��ɕ��ʂ�Cons/Nil�X�g���[���ɕϊ������Ɏ擾������@�ł���B
��҂̕ϊ��͐M�p�Ȃ�Ȃ� �\ ���i�ȃ��i�h�ɑ΂��郂�i�f�B�b�N�Ȋ֐��I�X�g���[���ɂ��Ă͔��U���邩�炾�B
�ȉ��̃e�N�j�b�N�͌�҂̏ꍇ�ł����삷��B

> {-# LANGUAGE Rank2Types #-}
> module Streams where
> import Control.Monad.Identity

�i�����ɂȂ�\���̂���j�X�g���[����\���ł���ʓI�ȕ��@�́A�ȉ��́u�ċA�I�v�^�̃f�[�^�\���Ƃ��ĕ\�����@���B

> data Stream a = Nil | Cons a (() -> Stream a)

��`�����i�Ȍ���ɂ����Ă͂܂�悤�ɁA�T���N (thunking) �͖�������Ă���B
�X�g���[���������֐��I�ɕ\�����邱�Ƃ��ł���B�ȉ��͍ċA�I�Łu�Ȃ��v���A�����N2�̌^�ł���B

> newtype FStream a = SFK (forall ans. SK a ans -> FK ans -> ans)
> type FK ans = () -> ans            -- ���s�p��
> type SK a ans = a -> FK ans -> ans -- �����p��
> unSFK (SFK a) = a

newtype �̃^�O�𖳎�����ƁiHaskell �œK�؂ɔC�Ӄ����N�^�������K�v�����邪�j�AFStream ��2�̌p���A�����p���Ǝ��s�p���̊֐��ƂȂ�B
��҂̓X�g���[�����v�f�������Ȃ��ۂɌĂяo�����B
��v�f�ȏ㎝���Ă���ۂɃX�g���[���͐����p�����Ăяo���B
�p���͂��̗v�f�Ƃق��̎��s�p�����󂯎���āA�X�Ȃ�v�f�����߂�B

���炩�ɁA��̕\���̊Ԃɂ͑Ή�������B���Ƃ��΁F

> fstream_to_stream fstream = unSFK fstream sk fk
>    where fk () = Nil
>	   sk a fk' = Cons a fk'
>
> stream_to_fstream Nil = SFK( \sk fk -> fk () )
> stream_to_fstream (Cons a rest) = 
>     SFK(\sk fk ->
>           sk a (\ () -> unSFK (stream_to_fstream (rest ())) sk fk))

�e�X�g�p�̃X�g���[��

> s1  = Cons 'a' (\ () -> Cons 'b' (\ () -> Cons 'c' (\ () -> Nil)))
> f1  = stream_to_fstream s1
> s1' = fstream_to_stream f1
>
> test1 = unSFK f1 (\a k -> a:(k())) (\() -> [])

	*Streams> test1
	"abc"

Mitch Wand �� D.Vaillancourt (ICFP'04 ������) �͂��`���I�ɑΉ���������Ă���B

�Ƃ͂����A��̕\���̊Ԃɂ͖��炩�ȈႢ������B
Stream �̏��߂�2�v�f�͗e�Ղɋ��߂���:

> stream_take:: Int -> Stream a -> [a]
> stream_take 0 _ = []
> stream_take n (Cons a r) = a : (stream_take (n-1) $ r ())

FStream ���ŏ��ɑS�� Stream �ɕϊ������ɍŏ���2�v�f�����߂�̂͂قƂ�Ǖs�\�Ɍ�����B
���̕ϊ��́A���i�f�B�b�N�Ȋ֐��I�X�g���[���������Ă���ꍇ�A�����ɂ����B

> newtype MFStream m a = MSFK (forall ans. MSK m a ans -> MFK m ans -> m ans)
> type MFK m ans = m ans                     -- failure continuation
> type MSK m a ans = a -> MFK m ans -> m ans -- success continuation
> unMSFK (MSFK a) = a
>
>
> mfstream_to_stream:: (Monad m) => MFStream m a -> m (Stream a)
> mfstream_to_stream mfstream = unMSFK mfstream sk fk
>    where fk = return Nil
>	   sk a fk' = fk' >>= (\rest -> return (Cons a (\ () -> rest)))

���� m �����i�ȃ��i�h�� fstream �������ł�������AStream �ւ̕ϊ��͔��U����B���ہA

> nats = nats' 0 where
>   nats' n = MSFK (\sk fk -> sk n (unMSFK (nats' (n+1)) sk fk))
>
> test2 = runIdentity (mfstream_to_stream nats >>= (return . stream_take 5))

  *Streams> test2
  [0,1,2,3,4]

������ IO �̂悤�Ȑ��i�ȃ��i�h���ƁF

> test3 = mfstream_to_stream nats >>= (print . stream_take 5)

�����\�������ɔ��U����B
���́Anats �̍ŏ��̗v�f��\������O�ɁA�X�g���[�����������肷�ׂĕϊ����Ȃ���΂Ȃ�Ȃ��̂��B

fstream �������̃f�[�^�\���ł��邩�̂悤�ɕ����ł���ƕ��������B
�ȉ��̊֐���1�v�f�ȏ������ FStream ��Ԃ��B
������̂́A���̃X�g���[���̐擪�Ɓu�c��̃X�g���[���v�̃y�A���B

> split_fstream :: FStream a -> FStream (a, FStream a)
> split_fstream fstream = unSFK fstream ssk caseB 
>  where caseB () = SFK(\a b -> b ())
>        ssk v fk = SFK(\a b -> 
> 		      a (v, (SFK (\s' f' -> 
> 				  unSFK (fk ())
>				  (\ (v'',x) _ -> s' v'' 
>				   (\ () -> unSFK x s' f'))
>				  f')))
>		        (\ () -> b ()))
>
> f11 = split_fstream f1
> e1  = unSFK f11 (\ (a,_) _ -> a)  undefined
> f1r = unSFK f11 (\ (_,r) _ -> r)  undefined
> f1rs = split_fstream f1r
> e2   = unSFK f1rs (\ (a,_) _ -> a)  undefined

���ہA�����X�g���[�� f1 �̍ŏ��̓�v�f�����o����̂��B

	*Streams> e1
	'a'
	*Streams> e2
	'b'

���i�f�B�b�N�ȗ�iChung-chieh Shan, Amr A. Sabry, Daniel P. Friedman �̘_������قƂ�ǂ��̂܂܈��p�����j

> split_mfstream :: Monad m => MFStream m a -> m (MFStream m (a, MFStream m a))
> split_mfstream m = unMSFK m ssk caseB
>  where caseB =    return $ MSFK(\a b -> b)
>        ssk v fk = return $ MSFK(\a b -> 
> 		      a (v, (MSFK (\s' f' -> 
> 				  fk >>= (\r -> unMSFK r
>				  (\ (v'',x) _ -> s' v'' (unMSFK x s' f'))
>				  f'))))
>		        b)


> mfstream_take:: Monad m => Int -> MFStream m a -> m [a]
> mfstream_take 0 _ = return []
> mfstream_take n m = do
>                     m' <- split_mfstream m
>                     (v,rs) <- unMSFK m' (\ (v,rs) _ -> return (v,rs) )
>                               undefined
>                     rl <- mfstream_take (n-1) rs
>                     return (v:rl)

> test2' = runIdentity (mfstream_take 5 nats)

	*Streams> test2'
	[0,1,2,3,4]


> test3' = mfstream_take 5 nats >>= print

���������₱�̏ꍇ��

	*Streams> test3'
	[0,1,2,3,4]

